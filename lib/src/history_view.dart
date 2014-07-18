part of clean_my_admin.page;

var cHistoryDocument = HistoryDocument.register();
class HistoryDocument extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new HistoryDocument(props));
    return (document, colapsed, showFilter) =>
        _registeredComponent(props: {'document': document,
          'colapsed': colapsed,
          'showFilter': showFilter});
  }
  HistoryDocument(props) : super(props);
  bool get colapsed => props['colapsed'];
  Map get doc => props['document'];
  get showFilter => props['showFilter'];

  render(){
    var before = doc["before"];
    var after = doc["after"];
    var bSame = noChangeIn(doc);
    return
    div({},[
      div({},[
        span({}, [
          b({}, "action: "),
          span({},"${doc["action"]}")
        ]),
        span({}, [
          b({}, "author: "),
          span({},"${doc["author"]}")
        ]),
        span({}, [
          b({}, "version: "),
          span({},"${doc["version"]}")
        ]),
        span({}, [
          b({}, "timestamp: "),
          span({},"${doc["timestamp"]}")
        ]),
        span({'class':'${bSame?'green':''}'}, [
          b({}, "Are documents same?: "),
          span({},"${bSame}")
        ]),
      ]),
      (colapsed)?
          div({'key':'merged'},
            pre({}, toPrettyMergeJson(before, after, " ", showFilter.value))
          )
        :
          div({"class":"leftright", 'key':'splitted'},[
            div({"class":"left"},[
              span({},"Before:"),
              pre({},toPrettyJson(before, " ", showFilter.value))
            ]),
            div({"class":"right"},[
              span({},"After:"),
              pre({},toPrettyJson(after, " ", showFilter.value))
            ]),
          ])
    ]);
  }
}

noChangeIn(doc) => same(new Map.from(doc['before'])..remove("__clean_version")..remove("__clean_collection"), new Map.from(doc['after'])..remove("__clean_version")..remove("__clean_collection"));
same(x,y) => const DeepCollectionEquality().equals(x,y);

toPrettyMergeJson(before, after, [indent = "", List<String> showFilter = const []]) {
  var indentValue = "  ";
  getBody(before, after, keys, getVal, hasKey) {
     var result = [];
     for (var key in keys) {
       var strKey = key;
       if (key is String) strKey = '"$key"';
       if (hasKey(before, key) && !hasKey(after, key)) strKey = "$strKey -> null";
       if (!hasKey(before, key) && hasKey(after, key)) strKey = "null -> $strKey";
       if (showFilter.isEmpty || shouldShowFilter(showFilter, key)) {
         var value = toPrettyMergeJson(getVal(before, key), getVal(after, key) , indent + indentValue, strip(showFilter, key.toString()));
         result.add('$indentValue$indent$strKey: $value');
       } else {
         if (key is String) key = '"$key"';
         result.add('$indentValue$indent$strKey: <- hidden');
       }
     }
     return result.join("\n");
   }

  basicType(x) =>
    x == null ||
    x is String ||
    x is num ||
    x is bool;

  basicToString(document){
    if (document == null) return "null";
    if (document is String) return '"${document}"';
    if (document is num) return document;
    if (document is bool) return document.toString();
  }

  if (basicType(before) && basicType(after)) {
    if (before == after) {
      return basicToString(before);
    } else {
      return '${basicToString(before)} -> ${basicToString(after)}';
    }
  }
  //HANDLE map
  if (before is Map || after is Map) {
    getKeyList(x) => x == null? [] : x.keys.toList();
    var keysAll = getKeyList(before)..addAll(getKeyList(after));
    var keysDistinct = keysAll.toSet().toList();
    var keys = keysDistinct..sort();
    getVal(doc,key) => doc == null? null : doc[key];
    hasKey(doc,key) => doc == null? false : doc.containsKey(key);
    return "{\n${getBody(before, after, keys, getVal, hasKey)}\n$indent}";
  }
  if (before is List || after is List) {
    var keys = [];
    getLength(x) => x == null? -1 : x.length;
    for (var i = 0; i < max(getLength(before), getLength(after)); i++) keys.add(i);
    getVal(doc,key) => doc == null? null : doc.length > key? doc[key]:null;
    hasKey(doc, key) => doc == null? false : doc.length > key;
    return "[\n${getBody(before, after, keys , getVal, hasKey)}\n$indent]";
  }
}

max(a,b) => a>b? a:b;
