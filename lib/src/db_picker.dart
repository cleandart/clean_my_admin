part of clean_my_admin.page;


var cDbPicker = DbPicker.register();
class DbPicker extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new DbPicker(props));
    return (dbRef) => _registeredComponent(props: {'dbRef': dbRef});
  }
  DbPicker(props) : super(props);
  DataReference get dbRef => props['dbRef'];

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
        mongoDbConfig.keys.map((dbKey) =>
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