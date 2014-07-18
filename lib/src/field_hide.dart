part of clean_my_admin.page;


var cFieldHider = FieldHider.register();
class FieldHider extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new FieldHider(props));
    return (hireListRef, subsNameRef) => _registeredComponent(props: {'hireListRef': hireListRef, 'subsNameRef':subsNameRef});
  }
  FieldHider(props): super(props);
  get hireListRef => props['hireListRef'];
  get subsNameRef => props['subsNameRef'];

  List<StreamSubscription> ss;
  didMount() {
    ss = [
      hideValue.onChange.listen((_) {
        try {
          hireListRef.value = JSON.decode(hideValue.value);
          hideValid.value = true;
        } catch (e){
          hideValid.value = false;
        }
        redraw();
      }),
      hideValid.onChange.listen((_) =>redraw()),
    ];
  }

  willUnmount() {
    ss.forEach((ss) => ss.cancel());
  }

  var hideValue = new DataReference('[]');
  var hideValid = new DataReference(true);

  render() =>
    div({},[
      b({}, "Fields to show:"),
      mI(value: hideValue, className: 'wideInput'),
      hideValid.value == false?
          span({},"INVALID JSON")
        :
          span({},""),
      span({},
        ((showingConstatns[subsNameRef.value] is Map)? showingConstatns[subsNameRef.value]: {}).
        keys.map((key) =>
            mButton(onClick: () => hideValue.value = showingConstatns[subsNameRef.value][key],
                    content: '$key - ')
        ).toList()
      )
    ]);
}
