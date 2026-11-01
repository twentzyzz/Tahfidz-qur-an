from pathlib import Path
from PIL import Image,ImageDraw
r=Path(__file__).resolve().parents[1]
im=Image.new('RGB',(1024,1024),'#064D3B');d=ImageDraw.Draw(im)
d.rounded_rectangle((80,80,944,944),radius=180,outline='#D9B65D',width=22)
d.polygon([(235,315),(455,270),(512,310),(569,270),(789,315),(789,720),(569,675),(512,720),(455,675),(235,720)],fill='#FFFDF4')
d.line([(512,320),(512,690)],fill='#B58A30',width=14)
for y in (385,455,525,595):
 d.line([(290,y),(450,y-20)],fill='#087F5B',width=14);d.line([(574,y-20),(734,y)],fill='#087F5B',width=14)
(r/'assets/branding').mkdir(parents=True,exist_ok=True);im.save(r/'assets/branding/logo.png')
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:im.resize((size,size),Image.Resampling.LANCZOS).save(r/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
for p in (r/'web/icons').glob('*.png'):
 size=192 if '192' in p.name else 512;im.resize((size,size),Image.Resampling.LANCZOS).save(p)
im.resize((32,32)).save(r/'web/favicon.png')
draw=r/'android/app/src/main/res/drawable';draw.mkdir(exist_ok=True)
vector='''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
<path android:fillColor="#FFFDF4" android:pathData="M26,34 L48,29 L54,33 L60,29 L82,34 L82,76 L60,71 L54,76 L48,71 L26,76 Z"/>
<path android:strokeColor="#B58A30" android:strokeWidth="2" android:pathData="M54,34 L54,72 M32,42 L47,39 M32,50 L47,47 M32,58 L47,55 M61,39 L76,42 M61,47 L76,50 M61,55 L76,58"/>
</vector>'''
(draw/'book_icon.xml').write_text(vector)
(draw/'notification_icon.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24"><path android:fillColor="#FFFFFFFF" android:pathData="M3,4 L11,6 L12,7 L13,6 L21,4 L21,19 L13,21 L12,22 L11,21 L3,19 Z"/></vector>''')
for folder in ['drawable','drawable-v21']:
 (r/f'android/app/src/main/res/{folder}/launch_background.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item android:drawable="@android:color/white"/><item android:width="160dp" android:height="160dp" android:gravity="center" android:drawable="@drawable/book_icon"/></layer-list>''')
p=r/'android/app/src/main/res/mipmap-anydpi-v26';p.mkdir(exist_ok=True);(p/'ic_launcher.xml').write_text('''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/launcher_background"/><foreground android:drawable="@drawable/book_icon"/></adaptive-icon>''')
(r/'android/app/src/main/res/values/colors.xml').write_text('<resources><color name="launcher_background">#064D3B</color></resources>')
for folder in ['values-v31','values-night-v31']:
 p=r/f'android/app/src/main/res/{folder}';p.mkdir(exist_ok=True);(p/'styles.xml').write_text('''<resources><style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar"><item name="android:windowSplashScreenBackground">#064D3B</item><item name="android:windowSplashScreenAnimatedIcon">@drawable/book_icon</item><item name="android:windowLightStatusBar">false</item></style></resources>''')
