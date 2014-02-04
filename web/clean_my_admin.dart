library player_list;

import 'package:angular/angular.dart';
import 'package:di/di.dart';
import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import 'dart:async';
import 'dart:convert';

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

  List playerlist =[];

  PlayerService rs;

  PlayerListController(PlayerService this.rs) {

    recalc(){
      print('Drawing');
      playerlist.clear();
      //print('Collection ${rs.playerSubscription.collection}');
      rs.playerSubscription.collection.forEach((Map doc){
        var newDoc = {};
         doc.keys.forEach((key){newDoc[key] = JSON.encode(doc[key]);});
         playerlist.add(newDoc);
      });
      print('Drawing finished');
    }
    recalc();

    rs.playerSubscription.collection.onChange.listen((ChangeSet changes){
      print('new Update');
      recalc();
      /*changes.addedItems.forEach((elem) {
        playerlist.add(elem);
      });
      changes.removedItems.forEach((elem) {
        playerlist.remove(elem);
      });
      playerlist.sort((a, b) => a["_id"].compareTo(b["_id"]));*/
      //playerlist = new MyList.set(rs.playerSubscription.collection.toList());
      print('finished');
    });
  }

  save(map, key) {
    print('Save ${map.runtimeType}');
    //var map = JSON.decode(mapString);
    print('Save $key in $map');
    print('Will search for  ${map['_id']}');
    var x = rs.playerSubscription.collection.findBy('_id', JSON.decode(map['_id']));
    print('Before ${x.runtimeType} $x');
    print('Will set key $key to >${JSON.decode(map[key])}<');
    x.first[key] = JSON.decode(map[key]);
    print('After: $x');
  }

  getReal(what) => rs.playerSubscription.collection.findBy('_id', JSON.decode(what['_id'])).first;

  getKeys(what) => what.keys.toList();

  addPlayer() {
    print('add Player');
    rs.playerSubscription.collection.add({});
  }
  removePlayer(what) {
    rs.playerSubscription.collection.remove(getReal(what));
  }
  addField(recipe, fieldname) => getReal(recipe)[fieldname] = "";
  removeField(recipe, fieldname) => getReal(recipe).remove(fieldname);
}