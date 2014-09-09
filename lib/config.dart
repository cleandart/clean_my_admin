library clean_my_admin.config;

final List allCollection = const ['player', 'club', 'user', 'match',
  'round', 'user_rank', 'bucket_user', 'transaction',
  'player_archive', 'psc_buckets', 'bucket_size', 'bucket_competition_info'];

const TESTING1_PORT = 27011;
const TESTING2_PORT = 27012;
const TESTING3_PORT = 27013;
const PROD_PORT = 27014;
const STAGE_PORT = 27017;

// CAUTION WHEN CHANGING THIS!!! This has to be the same port where live mongodb
// is tunelled to!
const LIVE_PORT = 27020;
// CAUTION WHEN CHANGING THIS!!!

final Map _SECURED_DBS = const {
  'live': 'mongodb://0.0.0.0:$LIVE_PORT/live',
  'live_prod': 'mongodb://0.0.0.0:$PROD_PORT/live',
  'live_stage': 'mongodb://0.0.0.0:$STAGE_PORT/live',
};

final Map _UNSECURED_DBS = const {
  'testing1': 'mongodb://0.0.0.0:$TESTING1_PORT/testing1',
  'testing2': 'mongodb://0.0.0.0:$TESTING2_PORT/testing2',
  'testing3': 'mongodb://0.0.0.0:$TESTING2_PORT/testing3',

  'local': 'mongodb://0.0.0.0:27017/devel',
  'devel': 'mongodb://stage.fandim.sk/devel', // TODO check if it works
  'stage': 'mongodb://0.0.0.0:$STAGE_PORT/stage',
  'prod': 'mongodb://0.0.0.0:$PROD_PORT/prod',
};

final mongoDbDefault = 'local';

Map mongoDbConfig(bool all) {
  var result;

  if (all) result = new Map.from(_UNSECURED_DBS)..addAll(_SECURED_DBS);
  else result = _UNSECURED_DBS;

  // Make sure that only db named live is connected to real live database.
  result.forEach((k, v) {
    if (k != 'live' && v.contains('$LIVE_PORT')) {
      throw new Exception('Live port ($LIVE_PORT) can be used only for db '
                          ' named "live"!');
    }
  });
  return result;
}

final filteringConstatns = {
  "user": {"not empty Email": '{"profile.email":{"\$ne": ""}}'},
};

final showingConstatns = {
  "user": {
    "profile": '["account", "profile", "productInfo.fanliga.account"]',
    "roundX": '["account", "profile", "productInfo.fanliga.account", "productInfo.fanliga.rounds.2014_115_X"]',
    "roundX-Rosters": '["account", "profile", "productInfo.fanliga.account", "productInfo.fanliga.rounds.2014_115_X.rosters"]',
    "roundX-Results": '["account", "profile", "productInfo.fanliga.account", "productInfo.fanliga.rounds.2014_115_X.results"]',
    "roundX-Archive": '["account", "profile", "productInfo.fanliga.account", "productInfo.fanliga.rounds.2014_115_X.archive"]',
  },
};
