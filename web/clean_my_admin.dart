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
             userSubscription, matchSubscription, roundSubscription,
             userRoundSubscription;

main() {
  print('Javascript started');
  react.setClientConfiguration();
  print('will create connection');
  connection =
      createHttpConnection("/resources/", new Duration(milliseconds: 2000));
  print('will create subscriber');
  subscriber = new Subscriber(connection);
  subscriber.init().then((_) {
    print('create subscription');
    playerSubscription = subscriber.subscribe('player')..restart();
    playerSubscription.collection.addIndex(['_id']);
    clubSubscription = subscriber.subscribe('club')..restart();
    clubSubscription.collection.addIndex(['_id']);
    userSubscription = subscriber.subscribe('user')..restart();
    userSubscription.collection.addIndex(['_id']);
    matchSubscription = subscriber.subscribe('match')..restart();
    matchSubscription.collection.addIndex(['_id']);
    roundSubscription = subscriber.subscribe('round')..restart();
    roundSubscription.collection.addIndex(['_id']);
    userRoundSubscription = subscriber.subscribe('user_rank')..restart();
    userRoundSubscription.collection.addIndex(['_id']);
    print('wait for subscription');
    Subscription.wait([playerSubscription, clubSubscription,
                       userSubscription, matchSubscription, roundSubscription])
    .then((_) {
      print('all done render page');
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

  var expanded = null;

  onEdit(id) {
    expanded = id;
    redraw();
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
    mButton(onClick: () => sellectSubs(userRoundSubscription), content: 'UserRound'),
        '  ',
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
           .map((item) => li({}, item['_id'] == expanded ? renderOneDocument(item) : renderReadOnlyDocument(onEdit, item))).toList()
       )
      :
      div({})
    ])
   ]);
  }

}

toPrettyJson(document, [indent = ""]) {
  var indentValue = "  ";
  getBody(keys) {
     var result = [];
     for (var key in keys) {
       var value = toPrettyJson(document[key], indent + indentValue);
       if (key is String) key = '"$key"';
       result.add('$indentValue$indent$key: $value');
     }
     return result.join("\n");
   }

  if (document == null) return "null";
  if (document is String) return '"${document}"';
  if (document is num) return document;
  if (document is bool) return document.toString();
  if (document is DataMap) {
    var keys = document.keys.toList()..sort();
    return "{\n${getBody(keys)}\n$indent}";
  }
  if (document is DataList) {
    var keys = [];
    for (var i = 0; i < document.length; i++) keys.add(i);
    return "[\n${getBody(keys)}\n$indent]";
  }
}

renderReadOnlyDocument(Function onEdit, DataMap document) {
  return [
          button({'onClick': (e) => onEdit(document['_id'])}, "Edit"),
          pre({}, toPrettyJson(document))
         ];
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