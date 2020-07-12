# clean-share-scrips

None of the following scripts are finished in any way. More like drafts.

find_non_scene_material.sh:\
Finds non-scene material in &lt;share-dir&gt; and stores logs in &lt;log-dir&gt;.

Use it with:\
./find_non_scene_data.sh &lt;log-dir&gt; &lt;share-dir&gt;\
./find_non_scene_data.sh '/disk0/logs/' '/disk0/share'

match_scene_material.py:\
Compares a given &lt;share-dir&gt; directory against the srrdb site. Downloads mismatched stuff etc.

Requirements:\
python\
rhash

Use it with:\
./match_scene_material.py &lt;share-dir&gt;\
./match_scene_material.py '/disk0/share'
