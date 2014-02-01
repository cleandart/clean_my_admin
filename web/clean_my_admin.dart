library recipe_book;

import 'package:angular/angular.dart';
import 'package:di/di.dart';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(
  targets: const ['recipe_book_controller'],
  override: '*')
import 'dart:mirrors';

class MyAppModule extends Module {
  MyAppModule() {
    type(RecipeBookController);
    type(RecipeService);
  }
}

main() {
  ngBootstrap(module: new MyAppModule());
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