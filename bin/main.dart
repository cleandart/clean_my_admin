import 'dart:async';
import 'package:clean_sync/server.dart';
import 'package:clean_ajax/server.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:clean_my_admin/config.dart';
import 'dart:convert';


void main(List<String> args) {
  runZoned(() {
    //MongoDatabase mongodb = new MongoDatabase('mongodb://stage.fanligy.sk/devel');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://stage.fandim.sk/stage');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://stage.fanligy.sk/testing');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://0.0.0.0:27018/live');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://0.0.0.0:27018/stage');
    MongoDatabase mongodb = new MongoDatabase('mongodb://0.0.0.0:27017/devel');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://prod:futbaltojehra@fanligy.sk/prod');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://devel:futbaltojehra@stage.fanligy.sk/devel');
    Future.wait(mongodb.init).then((_) {
      allCollection.forEach((collName){
        publish(collName, (_) => new Future.value(mongodb.collection(collName)));
      });
      publish('filtered', (args) =>
          new Future.value(mongodb.collection(args['collection'])
             .find(args['find'])
             ));
      Backend.bind('0.0.0.0', 8088, "").then((Backend backend) {

            // ROUTES
            backend.router.addRoute('resources', new Route('/resources/'));
            backend.router.addRoute('dart', new Route("/dart/*"));
            backend.router.addRoute('js', new Route("/js/*"));
            backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');

            /// AJAX Requests
            MultiRequestHandler multiRequestHandler = new MultiRequestHandler();
            multiRequestHandler.registerDefaultHandler(handleSyncRequest);
            backend.addView('resources', multiRequestHandler.handleHttpRequest);

            backend.addStaticView('dart', 'web/');
            backend.addStaticView('js', 'build/web/');
            print('Finished');
      });
    });
  });
}
