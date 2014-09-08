part of clean_my_admin.page;


var cDbPicker = DbPicker.register();
class DbPicker extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new DbPicker(props));
//    var _registeredComponent = tiles.registerComponent(() => new DbPicker());
    return (dbRef, availableDbNames) =>
        _registeredComponent(props: {'dbRef': dbRef, 'availableDbNames': availableDbNames});
  }
  DbPicker(props) : super(props);
  DataReference get dbRef => props['dbRef'];
  Iterable get availableDbNames => props['availableDbNames'];

  StreamSubscription ss;
  didMount() {
    ss = dbRef.onChange.listen((_) => redraw());
  }

  willUnmount() {
    if (ss != null) ss.cancel;
  }

  render() {
    return div({}, [
      b({},"Database: "),
      span({},
        availableDbNames.map((dbKey) =>
           span({},[
             mButton(className: (dbKey == dbRef.value)?'green':'',
                     onClick: () => dbRef.value = dbKey,
                     content: dbKey),
             ' - '
           ])
        ).toList()
      ),
    ]);
  }
}