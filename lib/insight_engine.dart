import 'app_state.dart';
import 'engines/burnout_engine.dart';
import 'engines/pattern_engine.dart';
import 'engines/predictive_engine.dart';
import 'engines/identity_engine.dart';
import 'engines/weak_window_engine.dart';

class InsightEngine {
  static String primary() {
    final h = KeelState.history;
    
    final today = KeelState.today;

    if (today != null && today.index < 40 && h.length < 3) {
      return "Today was difficult, but this does not indicate a downward trend yet.";
    }


    if (h.isEmpty) {
      return "Start reflecting to unlock insights.";
    }

    // 1️⃣ Burnout (highest priority)
    if (BurnoutEngine.isBurnoutRisk(h)) {
      return "Burnout risk detected. Reduce load and recover.";
    }

    // 2️⃣ Predictive collapse
    if (PredictiveEngine.isCollapseLikely(h)) {
      return "Sustained decline detected. Intervention now will prevent collapse.";
    }

    // 3️⃣ Identity drift
    if (IdentityEngine.isDrifting(h)) {
      return "Identity drift detected. You are losing clarity and direction.";
    }

    // 4️⃣ Weak window
    final weakWindow = WeakWindowEngine.detect(h);
    if (weakWindow != null) {
      return "Your weakest window is ${weakWindow.label}. Average index: ${weakWindow.avgIndex}.";
    }

    // 5️⃣ Momentum
    if (PredictiveEngine.isMomentumBuilding(h)) {
      return "Momentum is building. Protect this trajectory.";
    }

    // 6️⃣ Default
    return "Your cognitive state is stable and consistent.";
  }
}
