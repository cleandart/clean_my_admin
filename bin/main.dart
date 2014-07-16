import 'dart:async';
import 'package:clean_sync/server.dart';
import 'package:clean_ajax/server.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:clean_my_admin/config.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';

Future<MongoDatabase> getMongo(key) {
  if (mongoDb.containsKey(key)) {
     return new Future.value(mongoDb[key]);
  } else {
    mongoDb[key] = new MongoDatabase(mongoDbConfig[key]);
    return Future.wait(mongoDb[key].init).then((_) => mongoDb[key]);
  }
}


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
    Backend.bind('0.0.0.0', 8088, "").then((Backend backend) {

          // ROUTES
          backend.router.addRoute('resources', new Route('/resources/'));
          backend.router.addRoute('dart', new Route("/dart/*"));
          backend.router.addRoute('js', new Route("/js/*"));
          backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');

          /// AJAX Requests
          MultiRequestHandler multiRequestHandler = new MultiRequestHandler();
          multiRequestHandler.registerDefaultHandler(handleSyncRequest);
          multiRequestHandler.registerHandler('getHistory', handleHistoryRequest);


          backend.addView('resources', multiRequestHandler.handleHttpRequest);

          backend.addStaticView('dart', 'web/');
          backend.addStaticView('js', 'build/web/');
          print('Finished');
    });
  });
}


handleHistoryRequest(ServerRequest sr) {
  var db = sr.args['db'];
  var collName = sr.args['collection'];
  var id = sr.args['_id'];
  return getMongo(db).then((mongoDb){
     var collection =  mongoDb.rawDb.collection('__clean_${collName}_history');
     var collCursor = collection.find(
       new SelectorBuilder().eq("before._id", id)
       .or(new SelectorBuilder().eq("after._id", id))
       .sortBy('timestamp', descending: true)
       .limit(1000));
    var res = collCursor.toList();
    return res.then((res1){
      res1.forEach((i) => i['_id'] = i['_id'].toString());
      res1.forEach((i) => i['timestamp'] = i['timestamp'].toString());
      return res1;
    });
  });

}
