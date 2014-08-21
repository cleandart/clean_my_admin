part of clean_my_admin.page;


var cTimestampSearch = TimestampSearch.register();
class TimestampSearch extends tiles.Component {
  static register() {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new TimestampSearch(props));
    return (fromTimestamp, toTimestamp) => _registeredComponent(props: {
      'fromTimestamp': fromTimestamp,
      'toTimestamp': toTimestamp,
    });
  }
  TimestampSearch(props): super(props){
    fromStampValue.value = fromTimestamp.value.toString();
    toStampValue.value = toTimestamp.value.toString();
    from = {"value": fromStampValue, "valid": fromStampValid, 'updated': fromTimestamp};
    to = {"value": toStampValue, "valid": toStampValid, 'updated': toTimestamp};
  }
  get fromTimestamp => props['fromTimestamp'];
  get toTimestamp => props['toTimestamp'];
  var fromStampValue = new DataReference(null);
  var toStampValue = new DataReference(null);
  var fromStampValid = new DataReference(true);
  var toStampValid = new DataReference(true);
  List<StreamSubscription> ss;

  Map from;
  Map to;

  didMount() {

    List getListenersFor(stamps) =>
      [
        stamps['value'].onChange.listen((_) {
          if (stamps['updated'].value != stamps['value'].value) {
            try {
              stamps['updated'].value = DateTime.parse(stamps['value'].value);
              stamps['valid'].value = true;
            } catch (e){
              stamps['valid'].value = false;
            }
          }
          redraw();
        }),
        stamps['valid'].onChange.listen((_) =>redraw()),
        stamps['updated'].onChange.listen((_) => stamps['value'].value = stamps['updated'].value)
      ];

    ss = concat([from,to].map((l) => getListenersFor(l))).toList();

  }

  willUnmount() {
    ss.forEach((ss) => ss.cancel());
  }

  _renderStampInput(text, refs) =>
      div({},[
        b({}, text),
        mI(value: refs["value"], className: 'wideInput'),
        refs['valid'].value == false?
            span({},"INVALID DateTime format")
          :
            span({},""),

      ]);

  render() =>
    div({},[
      _renderStampInput("Search from timestamp: ",from),
      _renderStampInput("Search to timestamp: ",to),
    ]);
}
