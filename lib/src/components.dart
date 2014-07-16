part of clean_my_admin.page;

div(props,[children]) => tiles.div(props: props, children: children);
span(props,[children]) => tiles.span(props: props, children: children);
ul(props,[children]) => tiles.ul(props: props, children: children);
li(props,[children]) => tiles.li(props: props, children: children);
input(props,[children]) => tiles.input(props: props, children: children);
pre(props,[children]) => tiles.pre(props: props, children: children);
button(props,[children]) => tiles.button(props: props, children: children);
b(props,[children]) => tiles.b(props: props, children: children);
br() => tiles.br();


InputType mI = Input.register(/*constructor param*/);

typedef InputType({String id, String type, String className, value, String placeholder, bool readOnly, Function onChange, Function onBlur, String name});

class Input extends tiles.Component {
  static InputType register(/*constructor param*/) {
    var _registeredComponent = tiles.registerComponent(({props, children}) => new Input(props));
    return ({String id:null, String type:'text', String className:'', value:null,
      String placeholder:'', bool readOnly:false, onChange: null, onBlur: null, String name:''}) {

      //TODO maybe create it
      assert(value is DataReference);
      return _registeredComponent(props: {
        'id': id,
        'type' : type,
        'name': name,
        'inputClass': className,
        'placeholder': placeholder,
        'value': value,
        'readOnly' : readOnly,
        'onChange': onChange,
        'onBlur': onBlur
      });
    };
  }
  Input([props]): super(props);

  onChange(c,e) {
    print('onChange of input !!!!!!!!!!!!!!!!!${e} $c');
    var value = e.target.value;
    if (props['type'] == 'checkbox') value = e.target.checked;
    if (props['readOnly']) return;
    props['value'].value = value;
    redraw();
    if (props['onChange'] != null) props['onChange'](value);
  }

  onBlur(c,e) {
    if (props['onBlur'] != null)  props['onBlur'](e.target.value);
  }

  render() =>
     tiles.input(props: {
      'id': props['id'],
      'type': props['type'],
      'name': props['name'],
      'placeholder': props['placeholder'],
      'class': props['inputClass'],
      'checked': (props['type'] == 'checkbox')?props['value'].value:null,
      'value': props['value'].value,
    }, listeners: {'onChange': onChange, 'onBlur': onBlur});

}

mButton({String className:'',Function onClick:null, String content:'', bool isDisabled: false}) =>
    tiles.span(props: {'class': 'myButton $className'}, children:content, listeners: { 'onClick': (c,e) => (onClick==null || isDisabled)?null:onClick()});
