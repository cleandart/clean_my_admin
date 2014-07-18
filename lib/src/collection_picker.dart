part of clean_my_admin.page;

var cSubsPicker = SubsPicker.register();
class SubsPicker extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new SubsPicker(props));
    return (subName) => _registeredComponent(props: { 'subName': subName });
  }
  get subsNameRef => props['subName'];
  SubsPicker(props) : super(props);

  StreamSubscription ss;
  didMount() {
    ss = subsNameRef.onChange.listen((_) => redraw());
  }

  willUnmount() {
    if (ss != null) ss.cancel;
  }

  render() {
    return div({}, [
      b({},"Collection: "),
      span({},[
        span({},[
           'Custom collection',
           mI(value: subsNameRef),
           '  ',
        ]),
        span({},
          allCollection.map((sub) =>
            span({},[
              mButton(className: (sub == subsNameRef.value)?'green':'',
                  onClick: () => subsNameRef.value = sub,
                  content: sub),
              ' - '
            ])
          ).toList()
        )
      ]),
    ]);
  }
}