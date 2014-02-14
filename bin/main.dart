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
      Backend.bind([], new SHA256(), host: '0.0.0.0',
          port: 7070).then((Backend backend) {

            // ROUTES
            backend.router.addRoute('resources', new Route('/resources/'));
            backend.router.addRoute('static', new Route("/static/*"));
            backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');

            /// AJAX Requests
            MultiRequestHandler multiRequestHandler = new MultiRequestHandler();
            multiRequestHandler.registerDefaultHandler(handleSyncRequest);
            backend.addView('resources', multiRequestHandler.handleHttpRequest);

            backend.addStaticView('static', 'web/');
            print('Finished');
      });
    });
  });
}
