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

  List recipes;

  RecipeBookController(RecipeService rs) {
    recipes = [];
    rs.playerSubscription.collection.onChange.listen((_){
      print('new Update');

      recipes.clear();
      rs.playerSubscription.collection.forEach(
          (elem) => recipes.add(new Recipe(elem.toString()))
         );
      print('finished');
    });

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

class PlayerModel {
}

class Recipe {
  String name;

  Recipe(this.name);
}