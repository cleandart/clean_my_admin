import 'dart:async';
import 'package:args/args.dart';
import 'package:clean_sync/server.dart';
import 'package:clean_ajax/server.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:clean_my_admin/config.dart';
import 'package:mongo_dart/mongo_dart.dart';

class DbProvider {
  final Map _mongoDbConfig;
  Map _dbs = {};

  DbProvider(this._mongoDbConfig);

  Future<MongoDatabase> getMongo(dbName) {
    if (!canView(dbName)) {
      throw new Exception('Client is unauthorized to view database $dbName.');
    }

    if (_dbs.containsKey(dbName)) {
       return new Future.value(_dbs[dbName]);
    } else {
      _dbs[dbName] = new MongoDatabase(_mongoDbConfig[dbName]);
      return Future.wait(_dbs[dbName].init).then((_) => _dbs[dbName]);
    }
  }

  bool canView(dbName) => availableDbNames.contains(dbName);

  List get availableDbNames => _mongoDbConfig.keys.toList();

  waitForMongo(dbName, args) {
    return getMongo(dbName).then((mongoDb) =>
        mongoDb.collection(args['collection']).find(args['find'])
    );
  }
}

noChangeIn(doc) => same(
    new Map.from(doc['before'])..remove("__clean_version")..remove("__clean_collection"),
    new Map.from(doc['after'])..remove("__clean_version")..remove("__clean_collection"));

same(x,y) => x.toString() == y.toString();


void main(List<String> args) {
  var parser = new ArgParser();
  parser.addFlag('all', abbr: 'a', defaultsTo: true); // expose all databases
  parser.addOption('port', abbr: 'p', defaultsTo: '8091'); // expose all databases
  var pArgs = parser.parse(args);
  int port = int.parse(pArgs['port']);
  bool all = pArgs['all'];
  Map _mongoDbConfig = mongoDbConfig(all);
  DbProvider dbp = new DbProvider(_mongoDbConfig);

  runZoned(() {
    dbp.availableDbNames.forEach((mongoKey){
      publish('${mongoKey}-filtered', (args) => dbp.waitForMongo(mongoKey, args));
    });
    Backend.bind('0.0.0.0', port, "").then((Backend backend) {

      // ROUTES
      backend.router.addRoute('resources', new Route('/resources/'));
      backend.router.addRoute('dart', new Route("/dart/*"));
      backend.router.addRoute('js', new Route("/js/*"));
      backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');

      /// AJAX Requests
      MultiRequestHandler multiRequestHandler = new MultiRequestHandler();
      multiRequestHandler.registerDefaultHandler(handleSyncRequest);
      multiRequestHandler.registerHandler('getHistory',
          (sr) => handleHistoryRequest(sr, dbp));
      multiRequestHandler.registerHandler('getAuthorChanges',
          (sr) => handleAuthorChangesRequest(sr, dbp));
      multiRequestHandler.registerHandler('getAuthorChangesCount',
          (sr) => handleAuthorChangesCountRequest(sr, dbp));
      multiRequestHandler.registerHandler('getAvailableDbNames',
          (ServerRequest sr) => new Future.value(dbp.availableDbNames));


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

handleAuthorChangesCountRequest(ServerRequest sr, DbProvider dbp) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  return dbp.getMongo(db).then((mongoDb) {
    DbCollection collection = mongoDb.rawDb.collection('__clean_${collName}_history');
    return collection.count(getAuthorChangeSelector(sr.args, getCount: true));
  });
}

handleAuthorChangesRequest(ServerRequest sr, DbProvider dbp) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  return dbp.getMongo(db).then((mongoDb) {
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

handleHistoryRequest(ServerRequest sr, DbProvider dbp) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  var id = sr.args['_id'];
  var fromTimestamp = sr.args['fromTimestamp'];
  var toTimestamp = sr.args['toTimestamp'];
  return dbp.getMongo(db).then((mongoDb){
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
