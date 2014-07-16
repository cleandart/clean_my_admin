library player_list;

import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:clean_my_admin/config.dart';
import 'package:clean_my_admin/page.dart';

//import 'package:react/react_client.dart' as react;
//import "package:react/react.dart";
import 'package:tiles/tiles_browser.dart' as tiles;
import 'package:tiles/tiles.dart' as tiles;

Connection connection;
Subscriber subscriber;
Map<String, Subscription> subscriptions = {};

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

DataReference dbRef = new DataReference(mongoDbDefault);
var subsNameRef = new DataReference(null);

var filteringValue = new DataReference({});

var cFilteringPicker = FilteringPicker.register();
class FilteringPicker extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new FilteringPicker());
    return () => _registeredComponent();
  }
  FilteringPicker(): super({});

  List<StreamSubscription> ss;
  didMount() {
    ss = [
      filterValue.onChange.listen((_) {
        try {
          filteringValue.value = JSON.decode(filterValue.value);
          filterValid.value = true;
        } catch (e){
          filterValid.value = false;
        }
        redraw();
      }),
      filterValid.onChange.listen((_) =>redraw()),
      subsNameRef.onChange.listen((_) =>redraw()),
    ];
  }

  willUnmount() {
    ss.forEach((ss) => ss.cancel());
  }

  var filterValue = new DataReference('{}');
  var filterValid = new DataReference(true);

  render() =>
    div({},[
      b({},'Filtering value: '),
      mI(value: filterValue),
      filterValid.value == false?
          span({},"INVALID JSON")
        :
          span({},""),
      span({},
        ((filteringConstatns[subsNameRef.value] is Map)? filteringConstatns[subsNameRef.value]: {}).
        keys.map((key) =>
            mButton(onClick: () => filterValue.value = filteringConstatns[subsNameRef.value][key],
                    content: '$key - ')
        ).toList()
      )
    ]);
}

var fieldsHide = new DataReference([]);


Subscription prevSub;
DataReference<Subscription> subs = reactiveRef([dbRef], () {
  print('Restarting subsctiption with new database: ${dbRef.value}');
  if (prevSub != null) prevSub.dispose();
  prevSub = subscriber.subscribe('${dbRef.value}-filtered');
  startedSub.value = false;
  return prevSub;
});
DataReference startedSub = new DataReference(false);


var cAddDocument = AddDocument.register();
class AddDocument extends tiles.Component {
  static register() {
     var _registeredComponent = tiles.registerComponent(({props, children}) => new AddDocument());
     return () => _registeredComponent();
   }
  AddDocument(): super({});

  var documentToAdd = new DataReference('');
  var ss;
  didMount() {
    ss = documentToAdd.onChange.listen((_) => redraw());
  }

  willUnmount() {
    ss.forEach((ss) => ss.cancel());
  }

  render() =>
    div({}, [
      'Add document from JSON:',
      mI(value:documentToAdd),
      mButton(onClick: () { subs.value.collection.add(JSON.decode(documentToAdd.value)); redraw();}, content: 'Add'),
    ]);
}


DataReference skipDoc = new DataReference('0');
DataReference takeDoc = new DataReference('10');

var cLimitDocuments = LimitDocuments.register();
class LimitDocuments extends tiles.Component {
  static register() {
     var _registeredComponent = tiles.registerComponent(({props, children}) => new LimitDocuments());
     return () => _registeredComponent();
   }
  LimitDocuments(): super({});

  render() =>
    div({}, [
      span({},'Limit documents skip: '),
      mI(value:skipDoc),
      span({},'take: '),
      mI(value:takeDoc),
    ]);
}

var cDocumentView = DocumentView.register();
class DocumentView extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new DocumentView());
    return () => _registeredComponent();
  }
  DocumentView(): super({});

  Subscription get subsctiption => subs.value;

  var ss,ss1,ss2;
  didMount() {
    var ss1 = onChange([filteringValue, subsNameRef]).listen((_) {
      print('Restarting subsctiption: ${subsNameRef.value} filter: ${filteringValue.value}');
      subsctiption.restart({'collection': subsNameRef.value, 'find': filteringValue.value});
      startedSub.value = true;
      if (ss != null) ss.cancel();
      expanded.value = null;
      subsctiption.initialSync.then((_) => redraw()).catchError((e)=> print('Error: $e'));
      ss = subsctiption.collection.onChange.listen((_) => redraw());
    });
    var ss2 = onChange([
      startedSub,
      expanded,
      fieldsHide,
      subs,
      skipDoc,
      takeDoc,
    ]).listen((_) => redraw());
  }

  willUnmount() {
    if (ss1 != null) ss1.cancel();
    if (ss2 != null) ss2.cancel();
  }

  var expanded = new DataReference(null);

  showHistoryFnc(id) {
    showHistory.value = true;
    historyDbRef.value = dbRef.value;
    historySubsName.value = subsNameRef.value;
    historyIdPicker.value = id;
  }

  editDocument(id) {
    expanded.value = id;
  }

  render() =>
    div({},[
      cDbPicker(dbRef),
      cSubsPicker(subsNameRef),
      cAddDocument(),
      cFilteringPicker(),
      cFieldHider(fieldsHide, subsNameRef),
      cLimitDocuments(),
      cStatus(),
      mButton(onClick: () => expanded.value = '', content: "Go to readonly"),
      ul({},
         subsctiption.collection.skip(int.parse(skipDoc.value)).take(int.parse(takeDoc.value))
           .map((item) =>
             li({}, item['_id'] == expanded.value ?
                 renderOneDocument(item)
               :
                 renderReadOnlyDocument(showHistoryFnc, editDocument, item, fieldsHide.value)
               )
         ).toList()
       )
    ]);

  cStatus() {
    if (startedSub.value == false) return span({},"Nothing started");
    if (!subsctiption.initialSyncCompleted) {
      return span({},"Loading ...");
    } else {
      return span({},"Loaded count ${subsctiption.collection.length}");
    }
  }
}

var historyDbRef = new DataReference(mongoDbDefault);
var historySubsName = new DataReference('');
var historyIdPicker = new DataReference('hxj40106bcy0-1');
var historyResult = new DataReference([]);
var historyHide = new DataReference([]);

var cHistoryView = HistoryView.register();
class HistoryView extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new HistoryView());
    return () => _registeredComponent();
  }
  HistoryView(): super({});

  DataReference index = new DataReference(0);
  DataReference loading = new DataReference(false);
  DataReference colapsed = new DataReference(true);
  var ss;
  didMount(){
    ss = onChange([
      historyDbRef,
      historySubsName,
      historyIdPicker,
      historyResult,
      index,
      loading,
      historyHide,
      colapsed,
    ]).listen((_) => redraw());
  }

  willUnmount() {
    if (ss!= null) ss.cancel();
    historyResult.value = [];
  }

  loadHistory() {
    loading.value = true;
    index.value = 0;
    connection.send(() => new ClientRequest('getHistory', {
      'db': historyDbRef.value,
      'collection': historySubsName.value,
      '_id': historyIdPicker.value,
    })).then((result) {
      loading.value = false;
      historyResult.value = result;
    });
  }

  searchForChange() {
    var start = index.value + 1;
    while(start < historyResult.value.length && noChangeIn(historyResult.value[start])){
      print(start);
      start ++;
    }
    index.value = start;
  }

  render() =>
    div({},[
      cDbPicker(historyDbRef),
      cSubsPicker(historySubsName),
      div({},[
        'Id of document:',
        mI(value: historyIdPicker),
      ]),
      cFieldHider(historyHide, historySubsName),
      div({},
        mButton(onClick: loadHistory, content: "Load history <----- CLICK ME TO RELOAD")
      ),
      div({},[
        mButton(onClick: searchForChange, content: "Search for change"),
        mButton(onClick: () => index.value = index.value + 1 , content: "Previous"),
        span({}, ' - ${index.value + 1} / ${(historyResult.value as List).length}- '),
        mButton(onClick: () => index.value = index.value == 0? 0: index.value - 1 , content: "Next"),
        span({}, '   '),
        mButton(onClick: () => colapsed.value = !colapsed.value, content: "Colapse"),
      ]),
      drawResult(),
    ]);

    drawResult() {
      if (loading.value) return span({}, "loading");
      if (historyResult.value.length == 0) return span({},"No results");
      if (historyResult.value.length <= index.value) return span({},"Index out of range ${index.value + 1}/${historyResult.value.length}");
      return div({},[
        cHistoryDocument(historyResult.value[index.value], colapsed.value, historyHide),
      ]);
    }
}

DataReference showHistory = new DataReference(false);

class Page extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new Page());
    return () => _registeredComponent();
  }
  Page(): super({});

  var ss;
  didMount(){
    ss = showHistory.onChange.listen((_) => redraw());
  }

  willUnmount() {
    if (ss!= null) ss.cancel();
  }

  render() =>
    div({},[
      span({},[
        mButton(className:(!showHistory.value)?'green':'',
            onClick: () => showHistory.value = false,
            content: 'Document mode'),
        span({},'    -    '),
        mButton(className:(showHistory.value)?'green':'',
            onClick: () => showHistory.value = true,
            content: 'History mode'),
      ]),
      div({},
        showHistory.value?
            cHistoryView()
          :
            cDocumentView()
      )
    ]);
}
