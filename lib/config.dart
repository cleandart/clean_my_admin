library clean_my_admin.config;


final List allCollection = const ['player', 'club', 'user', 'match',
  'round', 'user_rank', 'bucket_user', 'transaction',
  'player_archive', 'psc_buckets', 'bucket_size', 'bucket_competition_info',
  'user_action_log'];



final mongoDbDefault = 'local';
final Map mongoDbConfig = {
  'local'  : 'mongodb://0.0.0.0:27017/devel',
  'stage'  : 'mongodb://0.0.0.0:27017/stage',
  'devel'  : 'mongodb://0.0.0.0:27017/devel',
  'prod'  : 'mongodb://0.0.0.0:27017/prod',

  'remote-devel'  : 'mongodb://stage.fandim.sk/devel',
  'ssh-stage'  : 'mongodb://0.0.0.0:27018/stage',
  'ssh-prod'   : 'mongodb://0.0.0.0:27018/prod',
  'ssh-live'   : 'mongodb://0.0.0.0:27018/live',
  'ssh-testing'   : 'mongodb://0.0.0.0:27018/testing',
};


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