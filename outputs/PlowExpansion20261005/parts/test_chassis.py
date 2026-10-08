import bpy, sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rlib as R
bpy.ops.wm.read_factory_settings(use_empty=True)
R.load_chassis(markers=True)
R.setup(res=(900, 700)); R.ground()
out = os.path.join(R.HERE, "renders", "test")
R.camera((9, -12, 8), (0, 0, 1.5)); R.render(os.path.join(out, "chassis_34.png"))
R.camera((20, 0, 1.5), (0, 0, 1.5), ortho=11); R.render(os.path.join(out, "chassis_side.png"))
R.camera((0, -20, 1.5), (0, 0, 1.5), ortho=9); R.render(os.path.join(out, "chassis_front.png"))
R.camera((0, 0, 20), (0, 0.001, 0), ortho=11); R.render(os.path.join(out, "chassis_top.png"))
