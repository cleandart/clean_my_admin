part of clean_my_admin.page;


var cTimestampSearch = TimestampSearch.register();
class TimestampSearch extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new TimestampSearch(props));
    return (fromTimestamp) => _registeredComponent(props: {'fromTimestamp': fromTimestamp});
  }
  TimestampSearch(props): super(props){
    stampValue.value = fromTimestamp.value.toString();
  }
  get fromTimestamp => props['fromTimestamp'];
  var stampValue = new DataReference(null);
  var stampValid = new DataReference(true);
  List<StreamSubscription> ss;

  didMount() {
    ss = [
      stampValue.onChange.listen((_) {
        if (fromTimestamp.value != stampValue.value) {
          try {
            fromTimestamp.value = DateTime.parse(stampValue.value);
            stampValid.value = true;
          } catch (e){
            stampValid.value = false;
          }
        }
        redraw();
      }),
      stampValid.onChange.listen((_) =>redraw()),
      fromTimestamp.onChange.listen((_) => stampValue.value = fromTimestamp.value),
    ];
  }

  willUnmount() {
    ss.forEach((ss) => ss.cancel());
  }

  render() =>
    div({},[
      b({}, "Search from timestamp:"),
      mI(value: stampValue, className: 'wideInput'),
      stampValid.value == false?
          span({},"INVALID DateTime format")
        :
          span({},"")
    ]);
}
