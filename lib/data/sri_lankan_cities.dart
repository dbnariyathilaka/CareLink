// Shared Sri Lankan city / town autocomplete data.
// Used by patient_onboarding2_screen.dart, edit_care_requirements_screen.dart,
// map_selection_screen.dart, and location_selection_screen.dart.
// Each entry includes lat/lng for coverage-area radius preview.

import 'dart:math' as math;

const List<Map<String, String>> sriLankanCities = [
  // ── Colombo District ─────────────────────────────────────
  {'city': 'Colombo',              'district': 'Colombo District',      'lat': '6.9271',  'lng': '79.8612'},
  {'city': 'Dehiwala',             'district': 'Colombo District',      'lat': '6.8520',  'lng': '79.8666'},
  {'city': 'Mount Lavinia',        'district': 'Colombo District',      'lat': '6.8389',  'lng': '79.8683'},
  {'city': 'Moratuwa',             'district': 'Colombo District',      'lat': '6.7732',  'lng': '79.8820'},
  {'city': 'Maharagama',           'district': 'Colombo District',      'lat': '6.8477',  'lng': '79.9266'},
  {'city': 'Nugegoda',             'district': 'Colombo District',      'lat': '6.8717',  'lng': '79.8995'},
  {'city': 'Kaduwela',             'district': 'Colombo District',      'lat': '6.9297',  'lng': '79.9841'},
  {'city': 'Malabe',               'district': 'Colombo District',      'lat': '6.9093',  'lng': '79.9693'},
  {'city': 'Battaramulla',         'district': 'Colombo District',      'lat': '6.9069',  'lng': '79.9249'},
  {'city': 'Piliyandala',          'district': 'Colombo District',      'lat': '6.8014',  'lng': '79.9216'},
  {'city': 'Kesbewa',              'district': 'Colombo District',      'lat': '6.8006',  'lng': '79.9360'},
  {'city': 'Homagama',             'district': 'Colombo District',      'lat': '6.8438',  'lng': '80.0000'},
  {'city': 'Pitipana',             'district': 'Colombo District',      'lat': '6.8312',  'lng': '80.0262'},
  {'city': 'Hanwella',             'district': 'Colombo District',      'lat': '6.9059',  'lng': '80.0834'},
  {'city': 'Avissawella',          'district': 'Colombo District',      'lat': '6.9459',  'lng': '80.2143'},
  {'city': 'Kolonnawa',            'district': 'Colombo District',      'lat': '6.9229',  'lng': '79.9421'},
  {'city': 'Sri Jayawardenepura Kotte', 'district': 'Colombo District', 'lat': '6.8876',  'lng': '79.9009'},
  {'city': 'Boralesgamuwa',        'district': 'Colombo District',      'lat': '6.8318',  'lng': '79.9119'},
  {'city': 'Ratmalana',            'district': 'Colombo District',      'lat': '6.8205',  'lng': '79.8831'},
  {'city': 'Angoda',               'district': 'Colombo District',      'lat': '6.9312',  'lng': '79.9296'},
  {'city': 'Mulleriyawa',          'district': 'Colombo District',      'lat': '6.9368',  'lng': '79.9580'},
  {'city': 'Padukka',              'district': 'Colombo District',      'lat': '6.8358',  'lng': '80.0900'},

  // ── Gampaha District ─────────────────────────────────────
  {'city': 'Negombo',              'district': 'Gampaha District',      'lat': '7.2095',  'lng': '79.8380'},
  {'city': 'Gampaha',              'district': 'Gampaha District',      'lat': '7.0889',  'lng': '80.0021'},
  {'city': 'Wattala',              'district': 'Gampaha District',      'lat': '6.9896',  'lng': '79.8879'},
  {'city': 'Ja-Ela',               'district': 'Gampaha District',      'lat': '7.0728',  'lng': '79.8910'},
  {'city': 'Kadawatha',            'district': 'Gampaha District',      'lat': '7.0034',  'lng': '79.9538'},
  {'city': 'Kiribathgoda',         'district': 'Gampaha District',      'lat': '7.0041',  'lng': '79.9248'},
  {'city': 'Ragama',               'district': 'Gampaha District',      'lat': '7.0291',  'lng': '79.9194'},
  {'city': 'Kelaniya',             'district': 'Gampaha District',      'lat': '6.9545',  'lng': '79.9207'},
  {'city': 'Katunayake',           'district': 'Gampaha District',      'lat': '7.1695',  'lng': '79.8866'},
  {'city': 'Minuwangoda',          'district': 'Gampaha District',      'lat': '7.1686',  'lng': '80.0059'},
  {'city': 'Mirigama',             'district': 'Gampaha District',      'lat': '7.2480',  'lng': '80.1282'},
  {'city': 'Veyangoda',            'district': 'Gampaha District',      'lat': '7.1461',  'lng': '80.0491'},
  {'city': 'Divulapitiya',         'district': 'Gampaha District',      'lat': '7.2908',  'lng': '80.0688'},
  {'city': 'Dompe',                'district': 'Gampaha District',      'lat': '7.0222',  'lng': '80.0706'},
  {'city': 'Attanagalla',          'district': 'Gampaha District',      'lat': '7.1580',  'lng': '80.0773'},
  {'city': 'Biyagama',             'district': 'Gampaha District',      'lat': '6.9714',  'lng': '79.9688'},
  {'city': 'Weligampitiya',        'district': 'Gampaha District',      'lat': '6.9606',  'lng': '79.9003'},

  // ── Kalutara District ─────────────────────────────────────
  {'city': 'Kalutara',             'district': 'Kalutara District',     'lat': '6.5854',  'lng': '79.9607'},
  {'city': 'Panadura',             'district': 'Kalutara District',     'lat': '6.7138',  'lng': '79.9040'},
  {'city': 'Horana',               'district': 'Kalutara District',     'lat': '6.7163',  'lng': '80.0606'},
  {'city': 'Beruwala',             'district': 'Kalutara District',     'lat': '6.4800',  'lng': '79.9830'},
  {'city': 'Aluthgama',            'district': 'Kalutara District',     'lat': '6.4363',  'lng': '80.0003'},
  {'city': 'Matugama',             'district': 'Kalutara District',     'lat': '6.5310',  'lng': '80.1080'},
  {'city': 'Ingiriya',             'district': 'Kalutara District',     'lat': '6.7434',  'lng': '80.1284'},
  {'city': 'Bandaragama',          'district': 'Kalutara District',     'lat': '6.6739',  'lng': '79.9878'},
  {'city': 'Wadduwa',              'district': 'Kalutara District',     'lat': '6.6642',  'lng': '79.9283'},
  {'city': 'Agalawatta',           'district': 'Kalutara District',     'lat': '6.5522',  'lng': '80.2196'},
  {'city': 'Bulathsinhala',        'district': 'Kalutara District',     'lat': '6.6208',  'lng': '80.2399'},
  {'city': 'Palindanuwara',        'district': 'Kalutara District',     'lat': '6.5097',  'lng': '80.2009'},

  // ── Kandy District ────────────────────────────────────────
  {'city': 'Kandy',                'district': 'Kandy District',        'lat': '7.2906',  'lng': '80.6337'},
  {'city': 'Peradeniya',           'district': 'Kandy District',        'lat': '7.2676',  'lng': '80.5958'},
  {'city': 'Gampola',              'district': 'Kandy District',        'lat': '7.1637',  'lng': '80.5752'},
  {'city': 'Nawalapitiya',         'district': 'Kandy District',        'lat': '7.0545',  'lng': '80.5336'},
  {'city': 'Katugastota',          'district': 'Kandy District',        'lat': '7.3227',  'lng': '80.6195'},
  {'city': 'Kundasale',            'district': 'Kandy District',        'lat': '7.2858',  'lng': '80.6795'},
  {'city': 'Wattegama',            'district': 'Kandy District',        'lat': '7.3571',  'lng': '80.7349'},
  {'city': 'Akurana',              'district': 'Kandy District',        'lat': '7.3574',  'lng': '80.6282'},
  {'city': 'Digana',               'district': 'Kandy District',        'lat': '7.2811',  'lng': '80.7224'},
  {'city': 'Udunuwara',            'district': 'Kandy District',        'lat': '7.2432',  'lng': '80.5563'},

  // ── Matale District ───────────────────────────────────────
  {'city': 'Matale',               'district': 'Matale District',       'lat': '7.4675',  'lng': '80.6234'},
  {'city': 'Dambulla',             'district': 'Matale District',       'lat': '7.8675',  'lng': '80.6519'},
  {'city': 'Galewela',             'district': 'Matale District',       'lat': '7.7498',  'lng': '80.6220'},
  {'city': 'Sigiriya',             'district': 'Matale District',       'lat': '7.9570',  'lng': '80.7603'},
  {'city': 'Rattota',              'district': 'Matale District',       'lat': '7.5360',  'lng': '80.7237'},
  {'city': 'Ukuwela',              'district': 'Matale District',       'lat': '7.4985',  'lng': '80.6603'},

  // ── Nuwara Eliya District ─────────────────────────────────
  {'city': 'Nuwara Eliya',         'district': 'Nuwara Eliya District', 'lat': '6.9497',  'lng': '80.7891'},
  {'city': 'Hatton',               'district': 'Nuwara Eliya District', 'lat': '6.8930',  'lng': '80.5963'},
  {'city': 'Talawakele',           'district': 'Nuwara Eliya District', 'lat': '6.9349',  'lng': '80.6572'},
  {'city': 'Ambagamuwa',           'district': 'Nuwara Eliya District', 'lat': '6.9872',  'lng': '80.6612'},
  {'city': 'Kotagala',             'district': 'Nuwara Eliya District', 'lat': '6.9220',  'lng': '80.6328'},
  {'city': 'Maskeliya',            'district': 'Nuwara Eliya District', 'lat': '6.8254',  'lng': '80.6215'},
  {'city': 'Norwood',              'district': 'Nuwara Eliya District', 'lat': '6.8917',  'lng': '80.6232'},

  // ── Galle District ────────────────────────────────────────
  {'city': 'Galle',                'district': 'Galle District',        'lat': '6.0535',  'lng': '80.2210'},
  {'city': 'Hikkaduwa',            'district': 'Galle District',        'lat': '6.1395',  'lng': '80.1066'},
  {'city': 'Ambalangoda',          'district': 'Galle District',        'lat': '6.2342',  'lng': '80.0562'},
  {'city': 'Elpitiya',             'district': 'Galle District',        'lat': '6.2913',  'lng': '80.1594'},
  {'city': 'Baddegama',            'district': 'Galle District',        'lat': '6.1842',  'lng': '80.1917'},
  {'city': 'Bentota',              'district': 'Galle District',        'lat': '6.4278',  'lng': '80.0015'},
  {'city': 'Balapitiya',           'district': 'Galle District',        'lat': '6.2759',  'lng': '80.0325'},
  {'city': 'Karandeniya',          'district': 'Galle District',        'lat': '6.1752',  'lng': '80.2527'},
  {'city': 'Neluwa',               'district': 'Galle District',        'lat': '6.2340',  'lng': '80.3395'},
  {'city': 'Imaduwa',              'district': 'Galle District',        'lat': '6.0968',  'lng': '80.3082'},
  {'city': 'Nagoda',               'district': 'Galle District',        'lat': '6.1126',  'lng': '80.2700'},

  // ── Matara District ───────────────────────────────────────
  {'city': 'Matara',               'district': 'Matara District',       'lat': '5.9549',  'lng': '80.5550'},
  {'city': 'Weligama',             'district': 'Matara District',       'lat': '5.9745',  'lng': '80.4293'},
  {'city': 'Dikwella',             'district': 'Matara District',       'lat': '5.9648',  'lng': '80.7009'},
  {'city': 'Akuressa',             'district': 'Matara District',       'lat': '6.0941',  'lng': '80.5125'},
  {'city': 'Hakmana',              'district': 'Matara District',       'lat': '6.0614',  'lng': '80.6433'},
  {'city': 'Kamburupitiya',        'district': 'Matara District',       'lat': '6.0456',  'lng': '80.4711'},
  {'city': 'Kotapola',             'district': 'Matara District',       'lat': '6.1225',  'lng': '80.6001'},
  {'city': 'Pitabeddara',          'district': 'Matara District',       'lat': '6.0799',  'lng': '80.5632'},
  {'city': 'Malimbada',            'district': 'Matara District',       'lat': '6.0220',  'lng': '80.4802'},
  {'city': 'Devinuwara',           'district': 'Matara District',       'lat': '5.9286',  'lng': '80.5751'},

  // ── Hambantota District ───────────────────────────────────
  {'city': 'Hambantota',           'district': 'Hambantota District',   'lat': '6.1241',  'lng': '81.1185'},
  {'city': 'Tangalle',             'district': 'Hambantota District',   'lat': '6.0241',  'lng': '80.7984'},
  {'city': 'Tissamaharama',        'district': 'Hambantota District',   'lat': '6.2826',  'lng': '81.2949'},
  {'city': 'Middeniya',            'district': 'Hambantota District',   'lat': '6.1050',  'lng': '80.8290'},
  {'city': 'Weeraketiya',          'district': 'Hambantota District',   'lat': '6.0693',  'lng': '80.8638'},
  {'city': 'Katuwana',             'district': 'Hambantota District',   'lat': '6.1087',  'lng': '80.7591'},
  {'city': 'Moragahaheena',        'district': 'Hambantota District',   'lat': '6.0810',  'lng': '80.8912'},
  {'city': 'Beliatta',             'district': 'Hambantota District',   'lat': '6.0494',  'lng': '80.7279'},
  {'city': 'Walasmulla',           'district': 'Hambantota District',   'lat': '6.0076',  'lng': '80.7573'},
  {'city': 'Ambalantota',          'district': 'Hambantota District',   'lat': '6.1249',  'lng': '81.0241'},
  {'city': 'Suriyawewa',           'district': 'Hambantota District',   'lat': '6.2218',  'lng': '81.0994'},
  {'city': 'Lunugamvehera',        'district': 'Hambantota District',   'lat': '6.3027',  'lng': '81.1972'},
  {'city': 'Okewela',              'district': 'Hambantota District',   'lat': '6.1820',  'lng': '80.9831'},
  {'city': 'Weerawila',            'district': 'Hambantota District',   'lat': '6.2370',  'lng': '81.2234'},
  {'city': 'Kirinda',              'district': 'Hambantota District',   'lat': '6.2109',  'lng': '81.3395'},
  {'city': 'Ranna',                'district': 'Hambantota District',   'lat': '6.0039',  'lng': '80.8262'},
  {'city': 'Hungama',              'district': 'Hambantota District',   'lat': '5.9896',  'lng': '80.9042'},
  {'city': 'Angunakolapelessa',    'district': 'Hambantota District',   'lat': '6.2124',  'lng': '81.1670'},

  // ── Rathnapura District ───────────────────────────────────
  {'city': 'Ratnapura',            'district': 'Rathnapura District',   'lat': '6.6828',  'lng': '80.3993'},
  {'city': 'Embilipitiya',         'district': 'Rathnapura District',   'lat': '6.3407',  'lng': '80.8459'},
  {'city': 'Balangoda',            'district': 'Rathnapura District',   'lat': '6.6500',  'lng': '80.6934'},
  {'city': 'Pelmadulla',           'district': 'Rathnapura District',   'lat': '6.5875',  'lng': '80.5103'},
  {'city': 'Eheliyagoda',          'district': 'Rathnapura District',   'lat': '6.8432',  'lng': '80.2286'},
  {'city': 'Kuruwita',             'district': 'Rathnapura District',   'lat': '6.7625',  'lng': '80.3600'},
  {'city': 'Kolonna',              'district': 'Rathnapura District',   'lat': '6.4143',  'lng': '80.6099'},
  {'city': 'Nivithigala',          'district': 'Rathnapura District',   'lat': '6.5124',  'lng': '80.5504'},
  {'city': 'Rakwana',              'district': 'Rathnapura District',   'lat': '6.3907',  'lng': '80.6602'},
  {'city': 'Imbulpe',              'district': 'Rathnapura District',   'lat': '6.5537',  'lng': '80.7395'},
  {'city': 'Godakawela',           'district': 'Rathnapura District',   'lat': '6.5004',  'lng': '80.8256'},
  {'city': 'Opanayake',            'district': 'Rathnapura District',   'lat': '6.6142',  'lng': '80.8049'},
  {'city': 'Kalawana',             'district': 'Rathnapura District',   'lat': '6.5271',  'lng': '80.3888'},

  // ── Kegalle District ──────────────────────────────────────
  {'city': 'Kegalle',              'district': 'Kegalle District',      'lat': '7.2527',  'lng': '80.3464'},
  {'city': 'Mawanella',            'district': 'Kegalle District',      'lat': '7.2506',  'lng': '80.4530'},
  {'city': 'Ruwanwella',           'district': 'Kegalle District',      'lat': '7.0283',  'lng': '80.2374'},
  {'city': 'Warakapola',           'district': 'Kegalle District',      'lat': '7.2437',  'lng': '80.2285'},
  {'city': 'Rambukkana',           'district': 'Kegalle District',      'lat': '7.3375',  'lng': '80.4076'},
  {'city': 'Deraniyagala',         'district': 'Kegalle District',      'lat': '6.9276',  'lng': '80.3348'},
  {'city': 'Galigamuwa',           'district': 'Kegalle District',      'lat': '7.1600',  'lng': '80.2701'},
  {'city': 'Bulathkohupitiya',     'district': 'Kegalle District',      'lat': '7.1201',  'lng': '80.2100'},
  {'city': 'Aranayake',            'district': 'Kegalle District',      'lat': '7.2136',  'lng': '80.3736'},

  // ── Kurunegala District ───────────────────────────────────
  {'city': 'Kurunegala',           'district': 'Kurunegala District',   'lat': '7.4863',  'lng': '80.3647'},
  {'city': 'Kuliyapitiya',         'district': 'Kurunegala District',   'lat': '7.4683',  'lng': '80.0425'},
  {'city': 'Narammala',            'district': 'Kurunegala District',   'lat': '7.4013',  'lng': '80.2335'},
  {'city': 'Wariyapola',           'district': 'Kurunegala District',   'lat': '7.5958',  'lng': '80.2678'},
  {'city': 'Maho',                 'district': 'Kurunegala District',   'lat': '7.7280',  'lng': '80.3004'},
  {'city': 'Pannala',              'district': 'Kurunegala District',   'lat': '7.5548',  'lng': '80.0836'},
  {'city': 'Alawwa',               'district': 'Kurunegala District',   'lat': '7.2998',  'lng': '80.2430'},
  {'city': 'Polgahawela',          'district': 'Kurunegala District',   'lat': '7.3424',  'lng': '80.3007'},
  {'city': 'Bingiriya',            'district': 'Kurunegala District',   'lat': '7.5695',  'lng': '80.1557'},
  {'city': 'Melsiripura',          'district': 'Kurunegala District',   'lat': '7.6520',  'lng': '80.5006'},
  {'city': 'Ibbagamuwa',           'district': 'Kurunegala District',   'lat': '7.6188',  'lng': '80.4477'},
  {'city': 'Ganewatta',            'district': 'Kurunegala District',   'lat': '7.5804',  'lng': '80.4095'},

  // ── Puttalam District ─────────────────────────────────────
  {'city': 'Puttalam',             'district': 'Puttalam District',     'lat': '8.0362',  'lng': '79.8283'},
  {'city': 'Chilaw',               'district': 'Puttalam District',     'lat': '7.5763',  'lng': '79.7955'},
  {'city': 'Wennappuwa',           'district': 'Puttalam District',     'lat': '7.3648',  'lng': '79.8464'},
  {'city': 'Marawila',             'district': 'Puttalam District',     'lat': '7.4680',  'lng': '79.8774'},
  {'city': 'Nattandiya',           'district': 'Puttalam District',     'lat': '7.4162',  'lng': '79.8476'},
  {'city': 'Anamaduwa',            'district': 'Puttalam District',     'lat': '7.9006',  'lng': '79.9840'},
  {'city': 'Dankotuwa',            'district': 'Puttalam District',     'lat': '7.3964',  'lng': '79.8957'},
  {'city': 'Lunuwila',             'district': 'Puttalam District',     'lat': '7.3375',  'lng': '79.8663'},
  {'city': 'Kalpitiya',            'district': 'Puttalam District',     'lat': '8.2310',  'lng': '79.7632'},

  // ── Anuradhapura District ─────────────────────────────────
  {'city': 'Anuradhapura',         'district': 'Anuradhapura District', 'lat': '8.3114',  'lng': '80.4037'},
  {'city': 'Kekirawa',             'district': 'Anuradhapura District', 'lat': '8.0288',  'lng': '80.5809'},
  {'city': 'Medawachchiya',        'district': 'Anuradhapura District', 'lat': '8.5092',  'lng': '80.4950'},
  {'city': 'Eppawala',             'district': 'Anuradhapura District', 'lat': '8.1714',  'lng': '80.4354'},
  {'city': 'Thambuttegama',        'district': 'Anuradhapura District', 'lat': '8.1009',  'lng': '80.5916'},
  {'city': 'Mihintale',            'district': 'Anuradhapura District', 'lat': '8.3510',  'lng': '80.5052'},
  {'city': 'Horowpothana',         'district': 'Anuradhapura District', 'lat': '8.6521',  'lng': '80.9162'},
  {'city': 'Nochchiyagama',        'district': 'Anuradhapura District', 'lat': '8.2462',  'lng': '80.2014'},
  {'city': 'Padaviya',             'district': 'Anuradhapura District', 'lat': '8.6986',  'lng': '80.7373'},

  // ── Polonnaruwa District ──────────────────────────────────
  {'city': 'Polonnaruwa',          'district': 'Polonnaruwa District',  'lat': '7.9403',  'lng': '81.0188'},
  {'city': 'Kaduruwela',           'district': 'Polonnaruwa District',  'lat': '7.9585',  'lng': '81.0310'},
  {'city': 'Medirigiriya',         'district': 'Polonnaruwa District',  'lat': '7.9969',  'lng': '80.9082'},
  {'city': 'Hingurakgoda',         'district': 'Polonnaruwa District',  'lat': '8.0462',  'lng': '80.9885'},
  {'city': 'Minneriya',            'district': 'Polonnaruwa District',  'lat': '8.0395',  'lng': '80.8913'},
  {'city': 'Dimbulagala',          'district': 'Polonnaruwa District',  'lat': '7.8564',  'lng': '81.1072'},

  // ── Badulla District ──────────────────────────────────────
  {'city': 'Badulla',              'district': 'Badulla District',      'lat': '6.9934',  'lng': '81.0550'},
  {'city': 'Bandarawela',          'district': 'Badulla District',      'lat': '6.8303',  'lng': '80.9898'},
  {'city': 'Haputale',             'district': 'Badulla District',      'lat': '6.7657',  'lng': '80.9607'},
  {'city': 'Ella',                 'district': 'Badulla District',      'lat': '6.8667',  'lng': '81.0462'},
  {'city': 'Welimada',             'district': 'Badulla District',      'lat': '6.9006',  'lng': '80.9166'},
  {'city': 'Mahiyanganaya',        'district': 'Badulla District',      'lat': '7.3269',  'lng': '81.0031'},
  {'city': 'Haldummulla',          'district': 'Badulla District',      'lat': '6.7228',  'lng': '80.8804'},
  {'city': 'Passara',              'district': 'Badulla District',      'lat': '6.9088',  'lng': '81.1620'},
  {'city': 'Lunugala',             'district': 'Badulla District',      'lat': '6.9723',  'lng': '81.1895'},

  // ── Moneragala District ───────────────────────────────────
  {'city': 'Moneragala',           'district': 'Moneragala District',   'lat': '6.8726',  'lng': '81.3495'},
  {'city': 'Wellawaya',            'district': 'Moneragala District',   'lat': '6.7363',  'lng': '81.1007'},
  {'city': 'Bibile',               'district': 'Moneragala District',   'lat': '7.1641',  'lng': '81.2109'},
  {'city': 'Buttala',              'district': 'Moneragala District',   'lat': '6.7443',  'lng': '81.2380'},
  {'city': 'Medagama',             'district': 'Moneragala District',   'lat': '6.7789',  'lng': '81.1671'},
  {'city': 'Siyambalanduwa',       'district': 'Moneragala District',   'lat': '7.0183',  'lng': '81.5388'},
  {'city': 'Thanamalwila',         'district': 'Moneragala District',   'lat': '6.5792',  'lng': '81.1614'},

  // ── Jaffna District ───────────────────────────────────────
  {'city': 'Jaffna',               'district': 'Jaffna District',       'lat': '9.6615',  'lng': '80.0255'},
  {'city': 'Chavakachcheri',       'district': 'Jaffna District',       'lat': '9.6577',  'lng': '80.1614'},
  {'city': 'Point Pedro',          'district': 'Jaffna District',       'lat': '9.8235',  'lng': '80.2345'},
  {'city': 'Kopay',                'district': 'Jaffna District',       'lat': '9.7050',  'lng': '80.0481'},
  {'city': 'Nallur',               'district': 'Jaffna District',       'lat': '9.6820',  'lng': '80.0178'},
  {'city': 'Tellippalai',          'district': 'Jaffna District',       'lat': '9.7427',  'lng': '80.0297'},

  // ── Kilinochchi District ──────────────────────────────────
  {'city': 'Kilinochchi',          'district': 'Kilinochchi District',  'lat': '9.3803',  'lng': '80.3919'},
  {'city': 'Paranthan',            'district': 'Kilinochchi District',  'lat': '9.4432',  'lng': '80.4170'},

  // ── Mannar District ───────────────────────────────────────
  {'city': 'Mannar',               'district': 'Mannar District',       'lat': '8.9760',  'lng': '79.9040'},
  {'city': 'Murunkan',             'district': 'Mannar District',       'lat': '8.7492',  'lng': '80.0986'},

  // ── Vavuniya District ─────────────────────────────────────
  {'city': 'Vavuniya',             'district': 'Vavuniya District',     'lat': '8.7514',  'lng': '80.4971'},
  {'city': 'Nedunkerni',           'district': 'Vavuniya District',     'lat': '8.9513',  'lng': '80.3736'},

  // ── Mullaitivu District ───────────────────────────────────
  {'city': 'Mullaitivu',           'district': 'Mullaitivu District',   'lat': '9.2671',  'lng': '80.8120'},
  {'city': 'Oddusuddan',           'district': 'Mullaitivu District',   'lat': '9.1855',  'lng': '80.6402'},

  // ── Trincomalee District ──────────────────────────────────
  {'city': 'Trincomalee',          'district': 'Trincomalee District',  'lat': '8.5874',  'lng': '81.2152'},
  {'city': 'Kinniya',              'district': 'Trincomalee District',  'lat': '8.6607',  'lng': '81.2228'},
  {'city': 'Kantale',              'district': 'Trincomalee District',  'lat': '8.3950',  'lng': '80.9932'},
  {'city': 'Mutur',                'district': 'Trincomalee District',  'lat': '8.4461',  'lng': '81.2610'},
  {'city': 'Kuchchaveli',          'district': 'Trincomalee District',  'lat': '8.8221',  'lng': '81.1018'},

  // ── Batticaloa District ───────────────────────────────────
  {'city': 'Batticaloa',           'district': 'Batticaloa District',   'lat': '7.7170',  'lng': '81.7005'},
  {'city': 'Kattankudy',           'district': 'Batticaloa District',   'lat': '7.6743',  'lng': '81.6869'},
  {'city': 'Valaichchenai',        'district': 'Batticaloa District',   'lat': '7.9085',  'lng': '81.5384'},
  {'city': 'Eravur',               'district': 'Batticaloa District',   'lat': '7.7670',  'lng': '81.6018'},
  {'city': 'Kaluwanchikudy',       'district': 'Batticaloa District',   'lat': '7.6965',  'lng': '81.6936'},

  // ── Ampara District ───────────────────────────────────────
  {'city': 'Ampara',               'district': 'Ampara District',       'lat': '7.2966',  'lng': '81.6724'},
  {'city': 'Kalmunai',             'district': 'Ampara District',       'lat': '7.4137',  'lng': '81.8190'},
  {'city': 'Akkaraipattu',         'district': 'Ampara District',       'lat': '7.2169',  'lng': '81.8518'},
  {'city': 'Sammanthurai',         'district': 'Ampara District',       'lat': '7.3771',  'lng': '81.7983'},
  {'city': 'Dehiattakandiya',      'district': 'Ampara District',       'lat': '7.6557',  'lng': '81.2931'},
  {'city': 'Uhana',                'district': 'Ampara District',       'lat': '7.4019',  'lng': '81.6068'},
  {'city': 'Padiyathalawa',        'district': 'Ampara District',       'lat': '7.5581',  'lng': '81.4085'},
];

/// Returns coordinates for a given city name, or null if not found.
Map<String, String>? cityCoords(String cityName) {
  final lower = cityName.toLowerCase();
  try {
    return sriLankanCities.firstWhere(
      (c) => c['city']!.toLowerCase() == lower,
    );
  } catch (_) {
    return null;
  }
}

/// Haversine formula — returns distance in km between two lat/lng points.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.pow(math.sin(dLng / 2), 2);
  return r * 2 * math.asin(math.sqrt(a.toDouble()));
}
