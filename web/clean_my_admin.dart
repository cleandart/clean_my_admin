library player_list;

import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:clean_my_admin/config.dart';

//import 'package:react/react_client.dart' as react;
//import "package:react/react.dart";
import 'package:tiles/tiles_browser.dart' as tiles;
import 'package:tiles/tiles.dart' as tiles;

Connection connection;
Subscriber subscriber;
Map<String, Subscription> subscriptions = {};


div(props,[children]) => tiles.div(props: props, children: children);
span(props,[children]) => tiles.span(props: props, children: children);
ul(props,[children]) => tiles.ul(props: props, children: children);
li(props,[children]) => tiles.li(props: props, children: children);
input(props,[children]) => tiles.input(props: props, children: children);
pre(props,[children]) => tiles.pre(props: props, children: children);
button(props,[children]) => tiles.button(props: props, children: children);
b(props,[children]) => tiles.b(props: props, children: children);

main() {
  print('Javascript started');
  tiles.initTilesBrowserConfiguration();
  print('will create connection');
  connection =
      createHttpConnection("/resources/", new Duration(milliseconds: 2000));
  print('will create subscriber');
  subscriber = new Subscriber(connection);
  subscriber.init().then((_) {
    print('create subscription');


    print('all done render page');
    var page = Page.register();
    tiles.mountComponent(page(), querySelector('#page'));
    print("Initial sync");

  }).catchError((e) {
    print(e);
  });
}


class Page extends tiles.Component {

  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new Page());
    return () => _registeredComponent();
  }

  var expanded = null;

  onEdit(id) {
    expanded = id;
    redraw();
  }

  Page() : super({});

  StreamSubscription updateSubscription;

  sellectSubs(subscriptionName){
    filteredSelected.value = null;
    if (!subscriptions.containsKey(subscriptionName)) {
      subscriptions[subscriptionName] = subscriber.subscribe(subscriptionName)..restart();
      subscriptions[subscriptionName].collection.addIndex(['_id']);
    }
    loading = 'Loading';
    redraw();
    subscriptions[subscriptionName].initialSync.then((_){
      loading = 'Finished';
      redraw();
    });
    selectedCollection = subscriptions[subscriptionName].collection;
    if (updateSubscription != null) updateSubscription.cancel();
    updateSubscription = selectedCollection.onChange.listen((_) { print('onChange');redraw();});
    redraw();
  }



  DataSet selectedCollection = null;
  var select = new DataReference('');
  var newDocument = new DataReference('');
  var deleteDocument = new DataReference('');
  var filed = new DataReference('_id');
  var loading = "Nothing loaded";

  DataMap filtered = new DataMap.from({'collection': 'round', 'find':'{}'});
  DataReference filteredSelected = new DataReference(null);
  Subscription filteredSubs = subscriber.subscribe('filtered');
  DataSet get filteredColl => filteredSubs.collection;
  DataReference filteredShow = new DataReference('[]');
  selectFiltered(){
    filteredSelected.value = true;
    redraw();
  }

  loadFiltered() {
    filteredSubs.restart({'collection':filtered['collection'], 'find': JSON.decode(filtered['find'])});
    if (updateSubscription != null) updateSubscription.cancel();
    updateSubscription = filteredSubs.collection.onChange.listen((_) { print('onChange');redraw();});
  }

  prefillFiltered(val) {
    filtered['collection'] = val;
    filtered['find'] = '{}';
    loadFiltered();
    redraw();
  }

  renderMenu() =>
    div({},[
      mButton(className: (filteredSelected.value==true)?'green':'', onClick: () => selectFiltered(), content: 'filtered'),
      '  ',
      span({},
        allCollection.map((sub) =>
         span({},[
           mButton(className: (subscriptions[sub]!=null)?'green':'', onClick: () => sellectSubs(sub), content: sub),
           ' - '
         ])
        ).toList()
      )
    ]);

  renderFiltered() =>
    div({},[
      renderMenu(),
      div({},
        allCollection.map((sub) =>
         span({},[
           mButton(className: (filtered['collection']==sub)?'green':'', onClick: () => prefillFiltered(sub), content: sub),
           ' - '
         ])
        ).toList()
      ),
      div({},[
        'Collection name',
        mI(value:filtered.ref('collection')),
        'filter property in JSON:',
        mI(value:filtered.ref('find')),
        mButton(onClick: loadFiltered, content: 'Load subs'),
        'show property as String in List:',
        mI(value:filteredShow),
        mButton(onClick: redraw, content: 'Refilter'),
      ]),
      div({},[
       'Total documents',
       filteredColl.length.toString()
      ]),
      ul({},
         filteredColl
           .map((item) =>
             li({}, item['_id'] == expanded ?
                 renderOneDocument(item)
               :
                 renderReadOnlyDocument(onEdit, item, JSON.decode(filteredShow.value))
             ))
           .toList()
       )
    ]);

  render() {
   if (filteredSelected.value == true) return renderFiltered();
   return
   div({},[
     div({}, renderMenu()),
     div({},[
      div({},'Loading state: $loading'),
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
          (selectedCollection != null)?selectedCollection.length.toString() : 'not selected',
        ]),
      (selectedCollection != null)?
        ul({},
           selectedCollection
             .where((item) => select.value =='' ||
                              item[filed.value] == JSON.decode(select.value) ||
                              (JSON.decode(select.value) != null &&
                                item[filed.value] !=null &&
                                item[filed.value].toString().toLowerCase() ==  JSON.decode(select.value).toString().toLowerCase()))
             .map((item) =>
               li({}, item['_id'] == expanded ?
                   renderOneDocument(item)
                 :
                   renderReadOnlyDocument(onEdit, item)
               ))
             .toList()
         )
        :
        div({})
      ])
     ])
    ]);
  }

}

shouldShowFilter(List<String> filter, String key) => filter.isEmpty ||
  filter.any((i) => i == key || i.startsWith('$key.'));

strip(List<String> filter) => (filter.isEmpty)? []:
  filter.where((String i) => i.contains('.')).map((i) => (i.substring(i.indexOf('.')+1))).toList();

toPrettyJson(document, [indent = "", List<String> showFilter = const []]) {
  var indentValue = "  ";
  getBody(keys) {
     var result = [];
     for (var key in keys) {
       if (showFilter.isEmpty || shouldShowFilter(showFilter, key)) {
         var value = toPrettyJson(document[key], indent + indentValue, strip(showFilter));
         if (key is String) key = '"$key"';
         result.add('$indentValue$indent$key: $value');
       } else {
         if (key is String) key = '"$key"';
         result.add('$indentValue$indent$key: <- hidden');
       }
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

renderReadOnlyDocument(Function onEdit, DataMap document, [showFilter = const []]) {
  return [
          tiles.button(listeners: {'onClick': (c,e) => onEdit(document['_id'])}, children: "Edit \\/"),
          pre({}, toPrettyJson(document, '', showFilter)),
          tiles.button(listeners: {'onClick': (c,e) => onEdit(document['_id'])}, children: "Edit /\\"),
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

class Input extends tiles.Component {
  static InputType register(/*constructor param*/) {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new Input(props));
    return ({String id:null, String type:'text', String className:'', value:null,
      String placeholder:'', bool readOnly:false, onChange: null, onBlur: null, String name:''}) {

      //TODO maybe create it
      assert(value is DataReference);
      return _registeredComponent(props: {
        'id': id,
        'type' : type,
        'name': name,
        'class': className,
        'placeholder': placeholder,
        'value': value,
        'readOnly' : readOnly,
        'onChange': onChange,
        'onBlur': onBlur
      });
    };
  }
  Input([props]): super(props);

  onChange(c,e) {
    var value = e.target.value;
    if (props['type'] == 'checkbox') value = e.target.checked;
    if (props['readOnly']) return;
    props['value'].value = value;
    redraw();
    if (props['onChange'] != null) props['onChange'](value);
  }

  onBlur(c,e) {
    if (props['onBlur'] != null)  props['onBlur'](e.target.value);
  }

  render() =>
     tiles.input(props: {
      'id': props['id'],
      'type': props['type'],
      'name': props['name'],
      'placeholder': props['placeholder'],
      'class': props['inputClass'],
      'checked': (props['type'] == 'checkbox')?props['value'].value:null,
      'value': props['value'].value,
    }, listeners: {'onChange': onChange, 'onBlur': onBlur});

}

mButton({String className:'',Function onClick:null, String content:'', bool isDisabled: false}) =>
    tiles.span(props: {'class': 'myButton $className'}, children:content, listeners: { 'onClick': (c,e) => (onClick==null || isDisabled)?null:onClick()});