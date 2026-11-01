# MueNee logo refinement — Campus Pop

วันที่: 2026-10-03. ผู้ใช้เลือก UI proposal 02 Campus Pop และสั่งให้แก้โลโก้ก่อน

## ปัญหาที่ตรวจจาก source จริง

- ส้อมเดิมมีซี่ที่ x=30,37,43,50,56 รวม 5 ซี่ ระยะห่าง 7/6/7/6 ไม่เท่ากัน และบางช่องเกือบติดเมื่อย่อ
- ขอบรูปทรงรวมในแนวนอนเดิมอยู่ประมาณ x=27..87 ซึ่งเยื้องจากศูนย์กลาง x=54 ของ viewport
- รอยยิ้มเดิมใช้ endpoint ที่ไม่สมมาตรและ control point ที่ไม่อยู่กลางระหว่าง endpoints
- SVG, Flutter painter และ Android drawable มี definitions แยกกัน ทำให้มีโอกาสแก้ไม่ตรงกัน

## รูปทรงใหม่

ไม่ใช้ image generation วาดรูปทรง ใช้ SVG / paths / raster exports ที่คำนวณแน่นอน:

- ส้อม **4 ซี่**: centers x=25,34,43,52 ระยะห่าง 9 หน่วย และทุกซี่เริ่ม y=28
- หนา 6 หน่วยเหมือนกันทุกเส้น; round cap / round join; ช่องระหว่างซี่ 3 หน่วย
- กึ่งกลางหัวส้อมและด้าม x=38.5
- ช้อน ellipse กึ่งกลาง (73,38), รัศมี 10×15 และด้ามตรงที่ x=73; ช้อนสูงกว่าซี่ส้อมเล็กน้อยตามสัดส่วนหัวช้อน ด้ามทั้งคู่จบ y=67
- รอยยิ้ม endpoints (26,78)/(82,78), control (54,92), สมมาตรเกี่ยวกับ x=54
- ขอบหมึกรวม [22,20]..[86,88] จึงมีกึ่งกลาง **(54,54)** ใน viewport 108×108
- พื้นคอรัล `#D82E50`, มุม 27 หน่วย; ไม่เปลี่ยนชื่อ MueNee หรือฟอนต์

SVG เป็น canonical source เดียว `scripts/generate_brand_assets.ps1` อ่าน paths แล้วสร้าง:

1. `lib/app/branding/brand_geometry.g.dart`, ใช้โดย `BrandMark`
2. Android `muenee_launcher_foreground.xml` — ใช้ร่วมกับ monochrome layer เดิม
3. Android `muenee_mark.xml` — splash สีเดิม แต่รูปทรงใหม่
4. PNG preview 512px และ legacy launcher PNG 48/72/96/144/192px

Android foreground ลดสเกล 0.78 รอบจุด (54,54) เพื่อรองรับ masking ไม่ฝัง rounded-square mask ใน foreground แยกจาก background ตาม [Android adaptive icon guidance](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

## ไฟล์ภาพและการย้อนดู

- [ภาพก่อน–หลังและตัวอย่างย่อ](../artifacts/brand-refinement/2026-10-03/logo-before-after.png)
- [โลโก้ใหม่ PNG](../assets/brand/muenee_launcher_512.png)
- [SVG ต้นฉบับ](../assets/brand/muenee_launcher.svg)
- ก่อนแก้ได้สำรอง 10 ไฟล์ที่เกี่ยวข้องไว้ใน `artifacts/brand-refinement/2026-10-03/before/` โดยไม่ได้ลบไฟล์ต้นฉบับสำรอง ไฟล์ Dart ใน archive ใช้ `.dart.txt` เพื่อไม่ให้ analyzer ตรวจเป็นโค้ดแอป

ภาพเปรียบเทียบ render จาก paths และ Flutter fonts จริง ไม่ใช่ภาพที่ AI วาด; ไม่ใช่ screenshot จาก APK หรือ Redmi

## Regenerate / check

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/generate_brand_assets.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/generate_brand_assets.ps1 -Check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/generate_brand_assets.ps1 -Check -CompileAndroid
```

ตัวเลือก ExecutionPolicy นี้จำกัดกับ process ที่รันสคริปต์ใน checkout ไม่แก้ policy ของเครื่องถาวร Generator ใช้ System.Drawing ที่มีใน Windows ไม่มี dependency ใหม่

## Local validation

- Focused Flutter tests ผ่าน 4 เคส: path parity ระหว่าง source/Flutter/Android, raster มี 4 ซี่กว้าง/ห่างเท่ากันและอยู่กลาง, widget ขนาดเล็ก/ใหญ่, opt-in preview export
- Raster check ที่ความละเอียด 10 pixels ต่อหน่วยยืนยัน bbox center (54,54) และ foreground ทั้งรูปอยู่ในวงกลมรัศมี 33 หน่วยหลัง scale0.78 (เป็น check แบบ conservative)
- ตรวจไฟล์ PNG และภาพเปรียบเทียบด้วยตา: ซี่แยกกัน, เส้นคงที่, ไม่มีส่วนสำคัญถูกตัดในภาพ preview
- Generator `-Check` ผ่านหลัง formatting ยืนยัน generated text/PNG ไม่ drift จาก SVG
- Android build-tools 36.0.0 `aapt2 compile` ผ่านสำหรับ foreground, splash และ adaptive-icon XML (resource compilation ไม่ใช่ full APK build)
- Full Flutter suite ผ่าน **122 tests** รวม 118 เดิมและ 4 ใหม่
- Analyzer รอบแรกตรวจไฟล์ backup ที่เป็น `.dart` ด้วย จึงเปลี่ยน archive เป็น `.dart.txt` โดยคงเนื้อหาเดิม แล้วรัน analyzer ใหม่: **No issues found** (`flutter analyze --no-pub`)

## ขอบเขต

เปลี่ยนเฉพาะ brand assets/painter และบันทึก direction ที่ผู้ใช้เลือก ไม่มีฟีเจอร์/ระบบ/ข้อมูลจริงเปลี่ยน ไม่เปลี่ยน Home เป็น Campus Pop ในงานนี้ ยังไม่ build APK / install emulator / install Redmi ดังนั้นไฟล์ APK เก่าและแอปที่ติดตั้งอยู่ยังใช้โลโก้เดิมจนกว่าจะ build และติดตั้งเวอร์ชันใหม่
