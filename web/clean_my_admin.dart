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
      createHttpConnection("/resources/", new Duration(milliseconds: 50));

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
    recipes = rs.recepies;
  }

}

// Defines our service called UserInformation.
class RecipeService {
  var _recepies = [
    new Recipe('My Appetizer','Appetizers',
        ["Ingredient 1", "Ingredient 2"],
        "Some Directions", 1, 'fonzie1.jpg'),
        new Recipe('My Salad','Salads',
            ["Ingredient 1", "Ingredient 2"],
            "Some Directions", 3, 'fonzie2.jpg'),
            new Recipe('My Soup','Soups',
                ["Ingredient 1", "Ingredient 2"],
                "Some Directions", 4, 'fonzie1.jpg'),
                new Recipe('My Main Dish','Main Dishes',
                    ["Ingredient 1", "Ingredient 2"],
                    "Some Directions", 2, 'fonzie2.jpg'),
                    new Recipe('My Side Dish','Side Dishes',
                        ["Ingredient 1", "Ingredient 2"],
                        "Some Directions", 3, 'fonzie1.jpg'),
                        new Recipe('My Awesome Dessert','Desserts',
                            ["Ingredient 1", "Ingredient 2"],
                            "Some Directions", 5, 'fonzie2.jpg'),
                            new Recipe('My So-So Dessert','Desserts',
                                ["Ingredient 1", "Ingredient 2"],
                                "Some Directions", 3, 'fonzie1.jpg'),
                                ];

  get recepies => _recepies;
  Subscription playerSubscription;

  RecipeService() {
    playerSubscription = subscriber.subscribe('player');
    playerSubscription.initialSync.then((_) {
      print("Initial sync");
    });
  }
}

class Recipe {
  String name;
  String category;
  List<String> ingredients;
  String directions;
  int rating;
  String imgUrl;

  Recipe(this.name, this.category, this.ingredients, this.directions,
      this.rating, this.imgUrl);
}