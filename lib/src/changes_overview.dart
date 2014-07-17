part of clean_my_admin.page;


var cChangeOverview = ChangeOverview.register();
class ChangeOverview extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new ChangeOverview(props));
    return (documents, histHide, sUp, sDown) =>
        _registeredComponent(props: {'documents': documents, 'histHide': histHide, 'sUp': sUp, 'sDown': sDown});
  }
  DataReference get docs => props['documents'];
  get sUp => props['sUp'];
  get sDown => props['sDown'];
  get histHide => props['histHide'];

  DataReference activeDoc = new DataReference(null);
  Map equalDocs = {};
  var ss;
  var recalcDone = true;
  var redrawCount = 10;
  var lastCalculated = -1;

  ChangeOverview(props) : super(props);

  didMount() {
    calculateSame(0);
    ss = [
          onChange([docs, activeDoc]).listen((_) => redraw()),
          docs.onChangeSync.listen((_) => calculateSame(0)),
          sUp.listen((_) => activeDoc.value != null ? activeDoc.value-- : null),
          sDown.listen((_) => activeDoc.value != null ? activeDoc.value++ : null)];
  }

  calculateSame(start) {
    recalcDone = false;
    for (int i = start; i < docs.value.length; i++) {
      if (i - start >= redrawCount) {
        redraw();
        return;
      }
      equalDocs[docs.value[i]['_id']] = noChangeIn(docs.value[i]);
      lastCalculated = i;
    }
    recalcDone = true;
    redraw();
  }

  Future noChangeInAsync(doc) => new Future(() => noChangeIn(doc));

  docClicked(id) {
    activeDoc.value = (activeDoc.value == id ? null : id);
    print(activeDoc.value);
  }

  willUnmount() {
    ss.forEach((s) => s.cancel());
  }

  didUpdate() {
    if (!recalcDone) {
      calculateSame(lastCalculated+1);
    }
  }

  render() {
    print("RENDERRR");
      return splittedView(table({},
          [tr({},[
            th({},'Author'),
            th({},'Time')]
          )]
          ..addAll(enumerate(docs.value).map((d) =>
          tr({"class": '${activeDoc.value == d.index ? "green" : ""}${equalDocs[d.value['_id']] ? " strike" : ""}'},[
            td({},'${d.value['author']}'),
            td({},'${d.value['timestamp']}'),
            td({}, mButton(onClick: () => docClicked(d.index), content: "View")),
          ])).toList())),
          (activeDoc.value == null || activeDoc.value >= docs.value.length) ? div({}) :
          cHistoryDocument(docs.value[activeDoc.value], true, histHide));
  }

  splittedView(left, right) {
    return div({"class":"leftright", 'key':'splittedOverview'},[
                div({"class":"left"},[
                  left
                ]),
                div({"class":"right"},[
                  right
                ]),
              ]);
  }

}