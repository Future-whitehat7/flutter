// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('CircleBorder', () {
    final CircleBorder c10 = const CircleBorder(const BorderSide(width: 10.0));
    final CircleBorder c15 = const CircleBorder(const BorderSide(width: 15.0));
    final CircleBorder c20 = const CircleBorder(const BorderSide(width: 20.0));
    expect(c10.dimensions, const EdgeInsets.all(10.0));
    expect(c10.scale(2.0), c20);
    expect(c20.scale(0.5), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.0), c10);
    expect(ShapeBorder.lerp(c10, c20, 0.5), c15);
    expect(ShapeBorder.lerp(c10, c20, 1.0), c20);
    final Matcher isUnitCircle = isPathThat(
      includes: <Offset>[
        const Offset(-0.6035617555492896, 0.2230970398703236),
        const Offset(-0.7738478165627277, 0.5640447581420576),
        const Offset(-0.46090034164788385, -0.692017006684612),
        const Offset(-0.2138540316101296, -0.09997005339529785),
        const Offset(-0.46919827227410416, 0.29581721423767027),
        const Offset(-0.43628713652733153, 0.5065324817995975),
        const Offset(0.0, 0.0),
        const Offset(0.49296904381712725, -0.5922438805080081),
        const Offset(0.2901141594861445, -0.3181478162967859),
        const Offset(0.45229946324502146, 0.4324593232323706),
        const Offset(0.11827752132593572, 0.806442226027837),
        const Offset(0.8854165569581154, -0.08604230149167624),
      ],
      excludes: <Offset>[
        const Offset(-100.0, -100.0),
        const Offset(-100.0, 100.0),
        const Offset(-1.1104403014186688, -1.1234939207590569),
        const Offset(-1.1852827482514838, -0.5029551986333607),
        const Offset(-1.0253256532179804, -0.02034402043932526),
        const Offset(-1.4488532714237397, 0.4948740308904742),
        const Offset(-1.03142206223176, 0.81070400258819),
        const Offset(-1.006747917852356, 1.3712062218039343),
        const Offset(-0.5241429900291878, -1.2852518410112541),
        const Offset(-0.8879593765104428, -0.9999680025850874),
        const Offset(-0.9120835110799488, -0.4361605900585557),
        const Offset(-0.8184877240407303, 1.1202520775469589),
        const Offset(-0.15746058420492282, -1.1905035795387513),
        const Offset(-0.11519948876183506, 1.3848147258237393),
        const Offset(0.0035741796943844495, -1.3383908620447724),
        const Offset(0.34408827443814394, 1.4514436242950461),
        const Offset(0.709487222145941, -1.3468012918181573),
        const Offset(0.6287522653614315, -0.8315879623940617),
        const Offset(0.9716071801865485, 0.24311969613525442),
        const Offset(0.7632982576031955, 0.8329765574976169),
        const Offset(0.9923766847309081, 1.0592617071813715),
        const Offset(1.2696730082820435, -1.0353385446957046),
        const Offset(1.4266154921521208, -0.8382633931857755),
        const Offset(1.298035226938996, -0.11544603567954526),
        const Offset(1.4143230992455558, 0.10842501221141165),
        const Offset(1.465352952354424, 0.6999947490821032),
        const Offset(1.0462985816010146, 1.3874230508561505),
        const Offset(100.0, -100.0),
        const Offset(100.0, 100.0),
      ],
    );
    expect(c10.getInnerPath(new Rect.fromCircle(center: Offset.zero, radius: 1.0).inflate(10.0)), isUnitCircle);
    expect(c10.getOuterPath(new Rect.fromCircle(center: Offset.zero, radius: 1.0)), isUnitCircle);
    expect(
      (Canvas canvas) => c10.paint(canvas, new Rect.fromLTWH(10.0, 20.0, 30.0, 40.0)),
      paints
        ..circle(x: 25.0, y: 40.0, radius: 10.0, strokeWidth: 10.0)
    );
  });
}
