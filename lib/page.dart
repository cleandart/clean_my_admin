library clean_my_admin.page;

import 'package:clean_my_admin/config.dart';
import 'package:clean_ajax/client_browser.dart';
import 'package:clean_data/clean_data.dart';
import 'package:clean_sync/client.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:tiles/tiles.dart' as tiles;
import 'package:collection/equality.dart';
import 'package:quiver/iterables.dart';

part 'src/components.dart';
part 'src/document.dart';
part 'src/db_picker.dart';
part 'src/collection_picker.dart';
part 'src/history_view.dart';
part 'src/field_hide.dart';
part 'src/search_timestamp.dart';
part 'src/changes_overview.dart';

var ss1 = window.onKeyDown.where((KeyboardEvent e) => e.keyCode == 'w');
var ss2 = window.onKeyDown.where((KeyboardEvent e) => e.keyCode == 's');