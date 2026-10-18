import tempfile, unittest, shutil, json
from pathlib import Path
from build_distribution import configure
ROOT=Path(__file__).resolve().parents[1]
class DistributionTests(unittest.TestCase):
 def stage(self, path):
  for folder in ["bootstrap","presentation","data"]:
   shutil.copytree(ROOT/folder,path/folder)
  for name in ["project.godot","export_presets.cfg"]:shutil.copyfile(ROOT/name,path/name)
  for name in ["desert","frost","swamp","volcanic","storm","void"]:
   p=path/("art/planets/v001/"+name+"-sky.png");p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b"later world")
   p=path/("art/characters/devourers-v001/dragon-"+name+".png");p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b"later dragon")
 def test_demo_removes_world_data_and_assets_and_keeps_shared_gameplay(self):
  with tempfile.TemporaryDirectory() as d:
   stage=Path(d);self.stage(stage)
   before=(stage/"bootstrap/core_loop_controller.gd").read_bytes()
   report=configure(stage,"demo")
   self.assertFalse((stage/"data/planets/desert.tres").exists())
   self.assertFalse((stage/"data/levels/void.tres").exists())
   self.assertFalse((stage/"art/characters/devourers-v001/dragon-storm.png").exists())
   self.assertTrue((stage/"data/planets/forest.tres").exists())
   self.assertEqual((stage/"bootstrap/core_loop_controller.gd").read_bytes(),before)
   self.assertIn('edition="demo"',(stage/"project.godot").read_text())
   self.assertEqual(report["world_ids"],[0])
 def test_full_keeps_seven_worlds_and_separate_application_identity(self):
  with tempfile.TemporaryDirectory() as d:
   stage=Path(d);self.stage(stage)
   report=configure(stage,"full")
   self.assertTrue((stage/"data/planets/desert.tres").exists())
   self.assertIn('org.cyberkingdom.demo',(stage/"export_presets.cfg").read_text())
   self.assertIn('Godot/app_userdata/Cyber Kingdom Demo',(stage/"project.godot").read_text())
   self.assertEqual(report["world_ids"],list(range(7)))
if __name__=="__main__":unittest.main()
