library clean_my_admin.config;

final List allCollection = const ['player', 'club', 'user', 'match',
  'round', 'user_rank', 'bucket_user', 'transaction',
  'player_archive', 'psc_buckets', 'bucket_size', 'bucket_competition_info'];

final Map _SECURED_DBS = const {
  'live': 'mongodb://0.0.0.0:27020/live',
  'live_stage': 'mongodb://0.0.0.0:27021/live',
  'live_prod': 'mongodb://0.0.0.0:27022/live',
};

final Map _UNSECURED_DBS = const {
  'testing1': 'mongodb://0.0.0.0:27011/testing1',
  'testing2': 'mongodb://0.0.0.0:27012/testing2',
  'testing3': 'mongodb://0.0.0.0:27013/testing3',

  'local': 'mongodb://0.0.0.0:27017/devel',
  'devel': 'mongodb://stage.fandim.sk/devel', // TODO check if it works
  'stage': 'mongodb://0.0.0.0:27017/stage',
  'prod': 'mongodb://0.0.0.0:27014/prod',
};

final mongoDbDefault = 'local';

Map mongoDbConfig(bool all) {
  if (all) return new Map.from(_UNSECURED_DBS)..addAll(_SECURED_DBS);
  return _UNSECURED_DBS;

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
