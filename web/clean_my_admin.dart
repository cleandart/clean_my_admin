library player_list;

import 'package:angular/angular.dart';
import 'package:di/di.dart';
import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import 'dart:async';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(
  targets: const ['recipe_book_controller'],
  override: '*')
import 'dart:mirrors';

Connection connection;
Subscriber subscriber;

class PlayerListModule extends Module {
  PlayerListModule() {
    type(PlayerListController);
    type(PlayerService);
  }
}

main() {
  connection =
      createHttpConnection("/resources/", new Duration(milliseconds: 200));

  subscriber = new Subscriber(connection);
  subscriber.init().then((_) {
    ngBootstrap(module: new PlayerListModule());
  }).catchError((e) {
    print(e);
  });
}

// Defines our service called UserInformation.
class PlayerService {
  Subscription playerSubscription;

  PlayerService() {
    playerSubscription = subscriber.subscribe('player');
    playerSubscription.initialSync.then((_) {
      print("Initial sync");
    });
  }
}

@NgController(
    selector: '[player-list]',
    publishAs: 'ctrl')
    class PlayerListController {

  List playerlist;

  PlayerService rs;

  PlayerListController(PlayerService this.rs) {
    playerlist = [];

    rs.playerSubscription.collection.onChange.listen((ChangeSet changes){
      print('new Update');
      changes.addedItems.forEach((elem) {
        playerlist.add(elem);
      });
      changes.removedItems.forEach((elem) {
        playerlist.remove(elem);
      });
      playerlist.sort((a, b) => a["_id"].compareTo(b["_id"]));
      print('finished');
    });
  }

  getKeys(DataMap what) => what.keys.toList();
  addPlayer() => rs.playerSubscription.collection.add({});
  removePlayer(DataMap what) => rs.playerSubscription.collection.remove(what);
  addField(recipe, fieldname) => recipe[fieldname] = "";
  removeField(DataMap recipe, fieldname) => recipe.remove(fieldname);
}