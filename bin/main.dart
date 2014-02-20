import 'dart:async';
import 'package:clean_sync/server.dart';
import 'package:clean_ajax/server.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:crypto/crypto.dart';

void main(List<String> args) {
  runZoned(() {
    MongoDatabase mongodb = new MongoDatabase('mongodb://stage:futbaltojehra@stage.fanligy.sk/stage');
    //MongoDatabase mongodb = new MongoDatabase('mongodb://0.0.0.0:27017/devel');
    Future.wait(mongodb.init).then((_) {
      publish('player', (_) => new Future.value(mongodb.collection('player')));
      publish('user', (_) => new Future.value(mongodb.collection('user')));
      publish('match', (_) => new Future.value(mongodb.collection('match')));
      publish('round', (_) => new Future.value(mongodb.collection('round')));
      publish('club', (_) => new Future.value(mongodb.collection('club')));
      Backend.bind('0.0.0.0', 8088, []).then((Backend backend) {

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
            backend.addStaticView('js', 'build/');
            print('Finished');
      });
    });
  });
}
