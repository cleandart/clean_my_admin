library player_list;

import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:react/react_client.dart' as react;
import "package:react/react.dart";

Connection connection;
Subscriber subscriber;
Subscription playerSubscription, clubSubscription,
             userSubscription, matchSubscription, roundSubscription;

main() {
  react.setClientConfiguration();

  connection =
      createHttpConnection("/resources/", new Duration(milliseconds: 200));

  subscriber = new Subscriber(connection);
  subscriber.init().then((_) {
    playerSubscription = subscriber.subscribe('player');
    playerSubscription.collection.addIndex(['_id']);
    clubSubscription = subscriber.subscribe('club');
    clubSubscription.collection.addIndex(['_id']);
    userSubscription = subscriber.subscribe('user');
    userSubscription.collection.addIndex(['_id']);
    matchSubscription = subscriber.subscribe('match');
    matchSubscription.collection.addIndex(['_id']);
    roundSubscription = subscriber.subscribe('round');
    roundSubscription.collection.addIndex(['_id']);
    Subscription.wait([playerSubscription, clubSubscription,
                       userSubscription, matchSubscription, roundSubscription])
    .then((_) {
      var page = Page.register();
      renderComponent(page(), querySelector('#page'));
      print("Initial sync");
    });
  }).catchError((e) {
    print(e);
  });
}


class Page extends Component {

  static register() {
    var _registeredComponent = registerComponent(() => new Page());
    return () => _registeredComponent({});
  }


  Page();

  StreamSubscription updateSubscription;

  sellectSubs(subscription){
    selectedCollection = subscription.collection;
    if (updateSubscription != null) updateSubscription.cancel();
    updateSubscription = selectedCollection.onChange.listen((_) { print('onChange');redraw();});
    redraw();
  }

  DataSet selectedCollection = null;
  var select = new DataReference('');
  var newDocument = new DataReference('');
  var deleteDocument = new DataReference('');
  var filed = new DataReference('_id');

  render() {
   return div({},[
    mButton(onClick: () => sellectSubs(playerSubscription), content: 'Players'),
    '  ',
    mButton(onClick: () => sellectSubs(userSubscription), content: 'Users'),
    '  ',
    mButton(onClick: () => sellectSubs(clubSubscription), content: 'Club'),
    '  ',
    mButton(onClick: () => sellectSubs(matchSubscription), content: 'Match'),
    '  ',
    mButton(onClick: () => sellectSubs(roundSubscription), content: 'Round'),
    '  ',
    svg({"width":"100", "height":"100"},[
      path({"stroke":"red", "d":"M 0 0 L 20 20"})
    ]),
    div({},[
      div({},[
        'Field key1',
        mI(value:filed),
        'value in JSON:',
        mI(value:select),
        mButton(onClick: () => redraw(), content: 'Filter'),
      ]),
      div({},[
        'value in JSON:',
        mI(value:newDocument),
        mButton(onClick: () { selectedCollection.add(JSON.decode(newDocument.value)); redraw();}, content: 'Add'),
      ]),
      div({},[
        'Remove document Id in json:',
        mI(value:deleteDocument),
        mButton(onClick: () {
          selectedCollection.remove(
              selectedCollection.findBy('_id', JSON.decode(deleteDocument.value)).first
          ); redraw();}, content: 'Delete'),
      ]),
      div({},[
        'Total documents',
        (selectedCollection != null)?selectedCollection.length : 'not selected',
      ]),
    (selectedCollection != null)?
      ul({},
         selectedCollection.where((item) => select.value =='' || item[filed.value] == JSON.decode(select.value)
         || (JSON.decode(select.value) != null && item[filed.value] !=null &&
                item[filed.value].toString().toLowerCase() ==  JSON.decode(select.value).toString().toLowerCase()))
           .map((item) => li({},renderOneDocument(item))).toList()
       )
      :
      div({})
    ])
   ]);
  }

}

renderOneDocument(DataMap document) {
  var addField = new DataReference('');
  var addFieldVal = new DataReference('');
  return ul({},
      [li({},[
                  'Key',
                  mI(value: addField),
                  'Value:',
                  mI(value: addFieldVal),
                  mButton(onClick: (){
                    print('Add Field ${addField.value}');
                    document[addField.value] = JSON.decode(addFieldVal.value);
                  }, content: 'Add Field'),
                  mButton(onClick: (){
                    window.alert(JSON.encode(document));
                  }, content: 'Show JSON'),
                  ])]..addAll(
      document.keys.map((key) {
        if (key == '_id') {
          return li({},[
                        b({},key),
                        ' ',
                        span({},document[key].toString())
                 ]);
        } else if (document[key] is DataMap) {
          return li({},[
              b({},key),
              mButton(onClick: (){
                    document[key] = {};
                    print('Clear ${key}');
              }, content: 'Clear map'),
              mButton(onClick: (){
                document.remove(key);
                print('Remove field ${key}');
              }, content: 'Remove field'),
              mButton(onClick: (){
                window.alert(JSON.encode(document[key]));
                print('Show json');
              }, content: 'Show json'),
              renderOneDocument(document[key])
              ]);//
        } else {
          var val = new DataReference(JSON.encode(document[key]));
          return li({},[
           b({},key),
           ' ',
           document[key].runtimeType.toString(),
           ' ',
           mI(value: val),
           ' - ',
           mButton(onClick: (){
             var newVal = JSON.decode(val.value);
             print('Save ${val.value} decoded: $newVal');
             document[key] = newVal;
           }, content: 'Save'),
            ' - ',
           mButton(onClick: (){
             document.remove(key);
             print('Remove ${val.value}');
           }, content: 'Remove field'),
          // span({},document[key].toString())
      ]);
     }

    }).toList())..addAll([
    ])
   );
}

InputType mI = Input.register(/*constructor param*/);

typedef InputType({String id, String type, String className, value, String placeholder, bool readOnly, Function onChange, Function onBlur, String name});

class Input extends Component {
  static InputType register(/*constructor param*/) {
    var _registeredComponent = registerComponent(() => new Input(/*constructor param*/));
    return ({String id:null, String type:'text', String className:'', value:null,
      String placeholder:'', bool readOnly:false, onChange: null, onBlur: null, String name:''}) {

      //TODO maybe create it
      assert(value is DataReference);

      return _registeredComponent({
        'id': id,
        'type' : type,
        'name': name,
        'className': className,
        'placeholder': placeholder,
        'value': value,
        'readOnly' : readOnly,
        'onChange': onChange,
        'onBlur': onBlur
      },null);
    };
  }

  onChange(e) {
    var value = e.target.value;
    if (props['type'] == 'checkbox') value = e.target.checked;
    if (props['readOnly']) return;
    props['value'].value = value;
    redraw();
    if (props['onChange'] != null) props['onChange'](value);
  }

  onBlur(e) {
    if (props['onBlur'] != null)  props['onBlur'](e.target.value);
  }

  render() {
    return input({
      'id': props['id'],
      'type': props['type'],
      'name': props['name'],
      'placeholder': props['placeholder'],
      'className': props['inputClass'],
      'checked': (props['type'] == 'checkbox')?props['value'].value:null,
      'value': props['value'].value,
      'onChange': onChange,
      'onBlur': onBlur
    });
  }
}

mButton({String className:'',Function onClick:null, String content:'', bool isDisabled: false}) =>
    span({'className': 'myButton',  'onClick': (e) => (onClick==null || isDisabled)?null:onClick()}, content);

/*

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
*/