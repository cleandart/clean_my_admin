import 'dart:async';
import 'package:clean_sync/server.dart';
import 'package:clean_ajax/server.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:clean_my_admin/config.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:collection/equality.dart';

Future<MongoDatabase> getMongo(key) {
  if (mongoDb.containsKey(key)) {
     return new Future.value(mongoDb[key]);
  } else {
    mongoDb[key] = new MongoDatabase(mongoDbConfig[key]);
    return Future.wait(mongoDb[key].init).then((_) => mongoDb[key]);
  }
}

noChangeIn(doc) => same(new Map.from(doc['before'])..remove("__clean_version")..remove("__clean_collection"), new Map.from(doc['after'])..remove("__clean_version")..remove("__clean_collection"));

same(x,y) => x.toString() == y.toString();

waitForMongo(key, args) {
  return getMongo(key).then((mongoDb) =>
      mongoDb.collection(args['collection'])
                 .find(args['find'])
  );
}


var mongoDb = {};

void main(List<String> args) {
  runZoned(() {
    mongoDbConfig.keys.forEach((mongoKey){
      publish('${mongoKey}-filtered', (args) => waitForMongo(mongoKey, args));
    });
    Backend.bind('0.0.0.0', 8091, "").then((Backend backend) {

          // ROUTES
          backend.router.addRoute('resources', new Route('/resources/'));
          backend.router.addRoute('dart', new Route("/dart/*"));
          backend.router.addRoute('js', new Route("/js/*"));
          backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');

          /// AJAX Requests
          MultiRequestHandler multiRequestHandler = new MultiRequestHandler();
          multiRequestHandler.registerDefaultHandler(handleSyncRequest);
          multiRequestHandler.registerHandler('getHistory', handleHistoryRequest);
          multiRequestHandler.registerHandler('getAuthorChanges', handleAuthorChangesRequest);
          multiRequestHandler.registerHandler('getAuthorChangesCount', handleAuthorChangesCountRequest);

          backend.addView('resources', multiRequestHandler.handleHttpRequest);

          backend.addStaticView('dart', 'web/');
          backend.addStaticView('js', 'build/web/');
          print('Finished');
    });
  });
}

getAuthorChangeSelector(Map args, {bool getCount}) {
  var author = args['author'];
  var fromTimestamp = args['fromTimestamp'];
  var toTimestamp = args['toTimestamp'];
  var skip = args["skip"];
  var limit = args["limit"];
  var selector = new SelectorBuilder().gte("timestamp",  DateTime.parse(fromTimestamp))
       .and(new SelectorBuilder().lte("timestamp",  DateTime.parse(toTimestamp)))
       .and(new SelectorBuilder().eq("author", author));
  if (!getCount) {
    selector = selector.sortBy("timestamp", descending: true)
                .skip(skip).limit(limit);
  }
  return selector;
}

handleAuthorChangesCountRequest(ServerRequest sr) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  return getMongo(db).then((mongoDb) {
    DbCollection collection = mongoDb.rawDb.collection('__clean_${collName}_history');
    return collection.count(getAuthorChangeSelector(sr.args, getCount: true));
  });
}

handleAuthorChangesRequest(ServerRequest sr) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  return getMongo(db).then((mongoDb) {
     DbCollection collection =  mongoDb.rawDb.collection('__clean_${collName}_history');
     var collCursor = collection.find(getAuthorChangeSelector(sr.args, getCount: false));
     var res = collCursor.toList();
     return res.then((res1) {
       // Because it cannot be JSONed
       var time = new DateTime.now();
       List changedDocs = res1.where((doc) => !noChangeIn(doc)).toList();
       changedDocs.forEach((i) => i['_id'] = i['_id'].toString());
       changedDocs.forEach((i) => i['timestamp'] = i['timestamp'].toString());
       print("Computing equality of ${res1.length} documents took ${new DateTime.now().difference(time)}");
       print("Number of changed docs : ${changedDocs.length}");
       return changedDocs;
     });
  });
}

handleHistoryRequest(ServerRequest sr) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  var id = sr.args['_id'];
  var fromTimestamp = sr.args['fromTimestamp'];
  var toTimestamp = sr.args['toTimestamp'];
  return getMongo(db).then((mongoDb){
     var collection =  mongoDb.rawDb.collection('__clean_${collName}_history');
     var collCursor = collection.find(new SelectorBuilder().gte("timestamp", DateTime.parse(fromTimestamp))
       .and(new SelectorBuilder().lte("timestamp", DateTime.parse(toTimestamp)))
       .and(new SelectorBuilder().eq("before._id", id)
       .or(new SelectorBuilder().eq("after._id", id))).excludeFields(["__clean_version", "__clean_collection"])
       .sortBy('timestamp', descending: true)
       .limit(200));
    var res = collCursor.toList();
    return res.then((res1){
      // Because it cannot be JSONed
      res1.forEach((i) => i['_id'] = i['_id'].toString());
      res1.forEach((i) => i['timestamp'] = i['timestamp'].toString());
      return res1;
    });
  });

}
