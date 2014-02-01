library recipe_book;

import 'package:angular/angular.dart';
import 'package:di/di.dart';
import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import "package:clean_router/client_browser.dart";
import 'dart:html';
import 'dart:async';
import 'dart:convert';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(
  targets: const ['recipe_book_controller'],
  override: '*')
import 'dart:mirrors';

Connection connection;
Subscriber subscriber;

class MyAppModule extends Module {
  MyAppModule() {
    type(RecipeBookController);
    type(RecipeService);
    type(HelloComponent);
  }
}

main() {
  connection =
      createHttpConnection("/resources/", new Duration(milliseconds: 200));

  subscriber = new Subscriber(connection);
  subscriber.init().then((_) {
    ngBootstrap(module: new MyAppModule());
  }).catchError((e) {
    print(e);
  });
}

@NgController(
    selector: '[recipe-book]',
    publishAs: 'ctrl')
    class RecipeBookController {

  String get name => mapa['name'];
  set name(val) => mapa['name'] = val;

  List recipes;

  RecipeService rs;

  DataMap mapa = new DataMap.from({'name':'meno'});

  RecipeBookController(RecipeService this.rs) {
    recipes = [];

    mapa.onChange.listen((val) {
      if (rs.playerSubscription.collection.length != 0)
        rs.playerSubscription.collection.first['name'] = mapa['name'];
    });
    rs.playerSubscription.collection.onChange.listen((ChangeSet changes){
      print('new Update');
      changes.addedItems.forEach((elem) {
        recipes.add(elem);
      });
      changes.removedItems.forEach((elem) {
        recipes.remove(elem);
      });
      print('finished');
    });
  }

  getKeys(DataMap what) {
    return what.keys.toList();
  }

  addPlayer() {
    rs.playerSubscription.collection.add({});
  }

  removePlayer(DataMap what) {
    rs.playerSubscription.collection.remove(what);
  }
}

// Defines our service called UserInformation.
class RecipeService {
  Subscription playerSubscription;

  RecipeService() {
    playerSubscription = subscriber.subscribe('player');
    playerSubscription.initialSync.then((_) {
      print("Initial sync");
    });
  }
}

@NgComponent(
    selector: "hello",
    templateUrl: "hello.html",
    publishAs: 'hellocmp'
)
class HelloComponent {
  @NgTwoWay('value')
  DataMap value;

  get keys => value.keys.toList();
}