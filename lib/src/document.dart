part of clean_my_admin.page;

shouldShowFilter(List<String> filter, String key) => filter.isEmpty ||
  filter.any((i) => i == key || i.startsWith('$key.'));

strip(List<String> filter, String key) => (filter.isEmpty)? []:
  filter.where((String i) => i.startsWith("$key.") && i.contains('.')).map((i) => (i.substring(i.indexOf('.')+1))).toList();

toPrettyJson(document, [indent = "", List<String> showFilter = const []]) {
  var indentValue = "  ";
  getBody(keys) {
     var result = [];
     for (var key in keys) {
       if (showFilter.isEmpty || shouldShowFilter(showFilter, key)) {
         var value = toPrettyJson(document[key], indent + indentValue, strip(showFilter, key.toString()));
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
  if (document is Map) {
    var keys = document.keys.toList()..sort();
    return "{\n${getBody(keys)}\n$indent}";
  }
  if (document is List) {
    var keys = [];
    for (var i = 0; i < document.length; i++) keys.add(i);
    return "[\n${getBody(keys)}\n$indent]";
  }
}

renderReadOnlyDocument(Function onShowHistory, Function onEdit, DataMap document, [showFilter = const []]) {
  return [
          tiles.button(listeners: {'onClick': (c,e) => onEdit(document['_id'])}, children: "Edit \\/"),
          tiles.button(listeners: {'onClick': (c,e) => onShowHistory(document['_id'])}, children: "Show history"),
          pre({}, toPrettyJson(document, '', showFilter)),
          tiles.button(listeners: {'onClick': (c,e) => onEdit(document['_id'])}, children: "Edit /\\"),
              tiles.button(listeners: {'onClick': (c,e) => onShowHistory(document['_id'])}, children: "Show history"),
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