import 'dart:async';
import 'dart:io';
import 'package:clean_sync/server.dart';
import 'package:clean_ajax/server.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:crypto/crypto.dart';

MongoDatabase mongodb;
Backend backend;

final String _staticRootDirProd = "./build/";
final String _staticRootDirStage = "./build/";
final String _staticRootDirDevel = "../web/";
Map config = {
   /**
    * Examples of mongo connection strings:
    * 'mongodb://127.0.0.1/databaseName' (if no authentication is used)
    * 'mongodb://user:password@fanligy.sk/databaseName'
    * 'mongodb://127.0.0.1:8080/databaseName' (if no default port is used)
    */
   'mongoConnString': 'mongodb://devel:futbaltojehra@fanligy.sk/devel',
   'server' : {
     'port' : 8080,
     'host': '0.0.0.0',
   },
   'fakeFbLogin' : true,
   'staticRootDir': _staticRootDirDevel,
   'staticImageDir': "${_staticRootDirDevel}images/",
   'staticPlayerImageDir': "${_staticRootDirDevel}images/player_pictures/",
   'staticClubImageDir': "${_staticRootDirDevel}images/clubs_pictures/",
   'fbUrlOfCurrentServer': 'http://0.0.0.0:8080/facebookLogin/',
   'fbAppId': '354858074657776',
};

/**
 * Create given collections and necessary indexes exist in database.
 */
void createCollections(MongoDatabase mongodb) {
  // <add here all collection names used in publishCollections>
  List collectionNames = ['user', 'player', 'club', 'match', 'round'];

  collectionNames.forEach((name) => mongodb.create_collection(name));
}

/**
 * Define which collections to expose to the client.
 */
void publishCollections() {
  // authenticated user (0 or 1 data objects)
  publish('loggedUser', (args) {
    return mongodb.collection('user').find({'_id': args['_authenticatedUserId']});
  });

  // <add new collections here>
  publish('player', (_) => new Future.value(mongodb.collection('player')));
  publish('club', (_) => new Future.value(mongodb.collection('club')));
  publish('user', (_) => new Future.value(mongodb.collection('user')));
  publish('match', (_) => new Future.value(mongodb.collection('match')));
  publish('round', (_) => new Future.value(mongodb.collection('round')));
}

void main(List<String> args) {
  runZoned(() {
    mongodb = new MongoDatabase('mongodb://127.0.0.1/database');
    Future.wait(mongodb.init).then((_) {
      createCollections(mongodb);
      publishCollections();
      Backend.bind([], new SHA256(), host: config['server']['host'],
          port: config['server']['port']).then((Backend _backend) {
        backend = _backend;
        initBackend(config);
        print("Hello");
      });
    });
  });
}

Future initBackend(Map config) {
  const STATIC = 'static';
  const RESOURCES = 'resources';

  backend.router.addRoute(RESOURCES, new Route('/resources/'));
  backend.router.addRoute(STATIC, new Route("/static/*"));
  backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');

  /// AJAX Requests
  MultiRequestHandler multiRequestHandler = new MultiRequestHandler();
  multiRequestHandler.registerDefaultHandler(handleSyncRequest);

  backend.addView(RESOURCES, multiRequestHandler.handleHttpRequest);

  /// NOT FOUND Requests
  backend.addNotFoundView((Request request) {
    request.response.write("<h1>Táto stránka neexistuje</h1>");
    request.response.close();
  });

  /// STATIC FILES Requests
  backend.addStaticView(STATIC, config['staticRootDir']);
}
