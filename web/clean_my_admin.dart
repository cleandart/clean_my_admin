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
  subscriber.init()
      .then((_) => connection.send(() => new ClientRequest('getAvailableDbNames', null)))
      .then((dbNames) {
        print('create subscription');

        print('all done render page');

        var views = {DOCUMENT: cDocumentView(() => cDbPicker(dbRef, dbNames)),
                     HISTORY: cHistoryView(() => cDbPicker(historyDbRef, dbNames)),
                     AUTHOR_CHANGES: cAuthorChangesView(() => cDbPicker(changesDbRef, dbNames)),};

        var page = Page.register();
        tiles.mountComponent(page(views), querySelector('#page'));
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
    var _registeredComponent = tiles.registerComponent(({props, children}) => new DocumentView(props));
    return (cDbPicker) => _registeredComponent(props: {'cDbPicker': cDbPicker});
  }
  DocumentView(props): super(props);

  get cDbPicker => props['cDbPicker'];

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
    showMode.value = HISTORY;
    historyDbRef.value = dbRef.value;
    historySubsName.value = subsNameRef.value;
    historyIdPicker.value = id;
  }

  editDocument(id) {
    expanded.value = id;
  }

  render() =>
    div({},[
      cDbPicker(),
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

var changesAuthorRef = new DataReference("adjust_account_cron");
var changesDbRef = new DataReference(mongoDbDefault);
var changesSubsNameRef = new DataReference('user');
var changesHideRef = new DataReference([]);
var changesLimitRef = new DataReference(10);
var changesSkipRef = new DataReference(0);
DataReference<DateTime> changesTimeFromRef = new DataReference(new DateTime.now().subtract(new Duration(hours:1)));
DataReference<DateTime> changesTimeToRef = new DataReference(new DateTime.now());
var changesAuthorResultRef = new DataReference([]);
var changesAuthorCountRef = new DataReference(0);

var cAuthorChangesView = AuthorChangesView.register();
class AuthorChangesView extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new AuthorChangesView(props));
    return (cDbPicker) => _registeredComponent(props: {'cDbPicker': cDbPicker});
  }

  AuthorChangesView(props): super(props);

  get cDbPicker => props['cDbPicker'];

  List<StreamSubscription> ss;
  DataReference loadingRef = new DataReference(false);
  DataReference index = new DataReference(0);

  didMount() {
    ss = [onChange([
      changesAuthorRef,
      changesDbRef,
      changesSubsNameRef,
      changesHideRef,
      changesAuthorResultRef,
      loadingRef,
      changesLimitRef,
      changesSkipRef,
      changesAuthorCountRef,
    ]).listen((_) => redraw())];
  }

  willUnmount() {
    ss.forEach((s) => s.cancel());
  }

  loadCount() {
    loadingRef.value = true;
    connection.send(() => new ClientRequest('getAuthorChangesCount', {
      'db': changesDbRef.value,
      'collection': changesSubsNameRef.value,
      'author': changesAuthorRef.value,
      'fromTimestamp' : changesTimeFromRef.value.toIso8601String(),
      'toTimestamp' : changesTimeToRef.value.toIso8601String(),
    })).then((result) {
      changesAuthorCountRef.value = result;
      loadingRef.value = false;
    });
  }

  loadChanges() {
    loadingRef.value = true;
    connection.send(() => new ClientRequest('getAuthorChanges', {
      'db': changesDbRef.value,
      'collection': changesSubsNameRef.value,
      'author': changesAuthorRef.value,
      'fromTimestamp' : changesTimeFromRef.value.toIso8601String(),
      'toTimestamp' : changesTimeToRef.value.toIso8601String(),
      'limit': changesLimitRef.value is String ? num.parse(changesLimitRef.value) : changesLimitRef.value,
      'skip': changesSkipRef.value is String ? num.parse(changesSkipRef.value) : changesSkipRef.value,
    })).then((result) {
      changesAuthorResultRef.value = result;
      loadingRef.value = false;
    });
  }

  _nextPage() {
    var newLimit = 2*changesLimitRef.value - changesSkipRef.value;
    changesSkipRef.value = changesLimitRef.value;
    changesLimitRef.value = newLimit;
  }

  _prevPage() {
    var newSkip = 2*changesSkipRef.value - changesLimitRef.value;

  }

  render() =>
      div({},[
        cDbPicker(),
        cSubsPicker(changesSubsNameRef),
        cFieldHider(changesHideRef, changesSubsNameRef),
        div({}, [
          b({}, "Changes by author: "),
          mI(value: changesAuthorRef),
        ]),
        cTimestampSearch(changesTimeFromRef, changesTimeToRef),
        div({},
          mButton(onClick: loadChanges, content: "Load changes <----- CLICK ME TO RELOAD")
        ),
        div({}, [
          b({}, "Skip: "),
          mI(value: changesSkipRef),
        ]),
        div({}, [
          b({}, "Limit: "),
          mI(value: changesLimitRef),
        ]),
        div({},[
          b({}, "Total document count: "),
          span({}, "${changesAuthorCountRef.value}"),
          mButton(onClick: loadCount, content: " RELOAD "),
        ]),
        loadingRef.value ? span({},"Loading.. please wait") : cAuthorChangeOverview(changesAuthorResultRef, changesHideRef, ss1, ss2),
      ]);

}

var historyDbRef = new DataReference(mongoDbDefault);
var historySubsName = new DataReference('user');
var historyIdPicker = new DataReference('hz3xnd21q7b0-1');
var historyResult = new DataReference([]);
var historyHide = new DataReference([]);
DataReference<DateTime> historyFromTimestamp = new DataReference(new DateTime.now().subtract(new Duration(hours:1)));
DataReference<DateTime> historyToTimestamp = new DataReference(new DateTime.now());
var historyDrawOverview = new DataReference(false);
var historyViewDocId = new DataReference(-1);

var cHistoryView = HistoryView.register();
class HistoryView extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new HistoryView(props));
    return (cDbPicker) => _registeredComponent(props: {'cDbPicker': cDbPicker});
  }
  HistoryView(props): super(props);

  get cDbPicker => props['cDbPicker'];

  DataReference index = new DataReference(0);
  DataReference loading = new DataReference(false);
  DataReference colapsed = new DataReference(true);
  var ss;
  didMount(){
    ss =
        [onChange([
      historyDbRef,
      historySubsName,
      historyIdPicker,
      historyResult,
      index,
      loading,
      historyHide,
      colapsed,
      historyDrawOverview,
    ]).listen((_) => redraw())];
  }

  willUnmount() {
    if (ss!= null) ss.forEach((s) => s.cancel());
    historyResult.value = [];
  }

  loadHistory() {
    historyDrawOverview.value = false;
    loading.value = true;
    index.value = 0;
    print("load");
    connection.send(() => new ClientRequest('getHistory', {
      'db': historyDbRef.value,
      'collection': historySubsName.value,
      '_id': historyIdPicker.value,
      'fromTimestamp' : historyFromTimestamp.value.toIso8601String(),
      'toTimestamp' : historyToTimestamp.value.toIso8601String(),
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

  searchFromTimestamp(DateTime time) {
    var start = 0;
    while((start < historyResult.value.length) && !DateTime.parse(historyResult.value[start]['timestamp']).isBefore(time)) {
      start++;
    }
    index.value = start-1;
  }

  toggle(DataReference d) => d.value = !d.value;

  render() =>
    div({},[
      cDbPicker(),
      cSubsPicker(historySubsName),
      cTimestampSearch(historyFromTimestamp, historyToTimestamp),
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
        mButton(onClick: () => toggle(colapsed), content: "Colapse"),
        br(),
        mButton(onClick: () => toggle(historyDrawOverview), content: "Show/Hide changes overview"),
      ]),
      historyDrawOverview.value ? cChangeOverview(historyResult, historyHide, ss1, ss2) : drawResult(),
    ]);

    drawResult() {
      if (loading.value) return span({}, "loading");
      if (historyResult.value.length == 0) return span({},"No results");
      if (historyResult.value.length <= index.value) return span({},"Index out of range ${index.value + 1}/${historyResult.value.length}");
      return div({},[
        cHistoryDocument(historyResult.value[index.value], colapsed.value, historyHide),
        span({},'Document timestamp: ${historyResult.value[index.value]['timestamp']}, runtime type: ${historyResult.value[index.value]['timestamp'].runtimeType}')
      ]);
    }
}

const HISTORY = "history";
const DOCUMENT = "document";
const AUTHOR_CHANGES = "authorChanges";

DataReference showMode = new DataReference(DOCUMENT);

class Page extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new Page(props));
    return (Map views) => _registeredComponent(props: {'views': views});
  }
  Page(props): super(props);

  Map get views => props['views'];

  var ss;
  didMount(){
    ss = showMode.onChange.listen((_) => redraw());
  }

  willUnmount() {
    if (ss!= null) ss.cancel();
  }

  _renderProperView() {
    var mode = showMode.value;
    if (views.keys.contains(mode)) return views[mode];
    throw new Exception('Unknowd mode $mode.');
  }

  _renderButton(mode, text) =>
    mButton(className:(showMode.value == mode)?'green':'',
        onClick: () => showMode.value = mode,
        content: text);

  render() =>
    div({},[
      span({},[
        _renderButton(DOCUMENT, 'Document mode'),
        span({},'    -    '),
        _renderButton(HISTORY, 'History mode'),
        span({},'    -    '),
        _renderButton(AUTHOR_CHANGES, 'Author changes mode')
      ]),
      div({}, _renderProperView())
    ]);
}
