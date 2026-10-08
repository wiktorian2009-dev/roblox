import json, os
s = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "stats_new.json")))
print("local AT = {" + ", ".join('%s = {"%s", %g, %g, %g}' % (k, v["pack"], v["at"][0], v["at"][1], v["at"][2]) for k, v in s.items()) + "}")
