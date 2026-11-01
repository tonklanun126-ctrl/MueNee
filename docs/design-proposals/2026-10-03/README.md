# MueNee: three UI design proposals

วันที่: 2026-10-03

สถานะ: **ผู้ใช้เลือก 02 Campus Pop แล้ว — โลโก้และหน้าชุดแรก (Home / Top 3 / Scan review) implement แล้ว; รอผู้ใช้ตรวจบน Emulator ก่อนทำ APK**

โลโก้ในภาพ mockup เป็นภาพแนวคิด ไม่ใช่ต้นฉบับสำหรับ production ผู้ใช้ระบุปัญหาซี่ส้อมผิดรูป/การจัดกลาง จึงแก้แยกด้วย SVG และ geometry ที่กำหนดแน่นอน ดู [logo refinement](../../brand-refinement-2026-10-03.md) ภาพ proposal รุ่นเดิมเก็บไว้เป็นประวัติ ไม่ถือว่ารูปทรงโลโก้ในภาพ AI ถูกอนุมัติ

เอกสารนี้ไม่แทนที่ `DESIGN.md` หรือเปลี่ยนสถานะของ phase ใด ๆ ภาพแนบเป็นภาพจำลองที่สร้างเพื่อเปรียบเทียบทิศทาง ไม่ใช่ screenshot จาก Flutter ที่นำไปใช้งานแล้ว และไม่ใช่หลักฐาน live Maps / Places / Gemini / Firebase acceptance

## ภาพสำหรับเลือกแนวทาง

แต่ละภาพแสดง Home / Top 3 / Scan review ของแบบเดียวกัน จากซ้ายไปขวา

- [01 — Coral Flow](../../../artifacts/design-proposals/2026-10-03/01-coral-flow-reviewed.png)
- [02 — Campus Pop](../../../artifacts/design-proposals/2026-10-03/02-campus-pop-reviewed.png)
- [03 — Midnight Coral](../../../artifacts/design-proposals/2026-10-03/03-midnight-coral-reviewed.png)

ภาพชุด `*-reviewed.png` เป็นชุดส่งมอบหลังเกลาข้อความใต้ preferences ให้เป็นคำชวนดู/แก้ไขที่เป็นกลาง ไม่ใช้รายการตัวอย่างเหมือนเป็นข้อจำกัดที่ผู้ใช้เลือกแล้ว ภาพรุ่นแรกเก็บแยกไว้โดยไม่ทับต้นฉบับ

## ฐานข้อมูลที่ใช้ตัดสินใจ

- อ่าน `AGENTS.md`, `PROJECT_CONTEXT.md`, `DESIGN.md` และ `docs/coral-companion-redesign.md` ฉบับใน checkout ปัจจุบัน ไม่มี `PROJECT.md` ใน checkout นี้ จึงยึด `PROJECT_CONTEXT.md` เป็นบริบทผลิตภัณฑ์
- ตรวจสีและฟอนต์ใน `lib/app/theme/app_theme.dart`, navigation จริงใน `lib/app/widgets/main_navigation_bar.dart` และ copy ของ Home / recommendations / food scan
- ตรวจภาพหน้าปัจจุบันใน `artifacts/coral-companion/`: Home, recommendations และ AI review ภาพเหล่านี้เป็น fixture ไม่ใช่ผลทดสอบบริการจริง
- รักษาสัญลักษณ์ส้อม–ช้อน–รอยยิ้มจาก `assets/brand/muenee_launcher_512.png` ไม่เปลี่ยนโลโก้ในรอบเสนอครั้งนี้

MueNee ช่วยนักศึกษาเลือกมื้ออาหารตามงบและข้อจำกัดอาหาร แล้วบันทึกมื้อ ไม่ใช่แอปสั่งอาหาร/เดลิเวอรี จุดประสงค์คือเลือกได้เร็วจาก Top 3 ที่มีเหตุผล ไม่ใช่เพิ่มเวลาไถ feed

## สิ่งที่ควรปรับจากหน้าปัจจุบัน

1. **Home:** ย่อ budget panel และข้อความประกอบเพื่อให้เห็นการตั้งค่ามื้อและ action หลักในช่วงแรกของจอ เพิ่มภาพอาหารที่พอดีโดยไม่ทำให้ผู้ใช้เข้าใจว่ามีผลแนะนำก่อนยืนยันข้อมูล
2. **Top 3:** ลดความสูงของแต่ละ card เพื่อเทียบตัวเลือกได้เร็ว แยกเมนู/ราคาเป็นลำดับแรก ระยะทางและโภชนาการเป็นลำดับรอง ย้ายคำอธิบายยาวไป disclosure
3. **Scan review:** เปลี่ยนจากฟอร์มยาวให้เริ่มด้วยภาพ/ชื่อ/ปริมาณที่ระบบสมมติ ตามด้วยค่าที่แก้ไขได้ และ CTA ยืนยันที่หาเจอง่าย
4. **ทุกหน้า:** ใช้ลำดับตัวอักษรและ spacing ร่วมกัน คงคำไทยที่ตรงไปตรงมาและสถานะจริง ลดการใช้กล่อง/ไอคอนที่ไม่ได้ช่วยตัดสินใจ

นี่เป็นข้อวินิจฉัยด้านดีไซน์จากเอกสาร/ภาพ fixture และโค้ดที่ตรวจ ไม่ใช่ผล user research หรือ usability test กับผู้ใช้จริง

## Reference research ผ่าน Chrome

| แหล่ง | แนวคิดที่นำมาปรับใช้ | สิ่งที่ไม่นำเข้ามาใน MueNee |
| --- | --- | --- |
| [Too Good To Go](https://www.toogoodtogo.com/en-us) | ภาพอาหาร/ไลฟ์สไตล์ที่มีน้ำหนัก, สีแบรนด์ที่จำง่าย, CTA หลักที่ชัด | การจอง/ชำระเงิน/รับสินค้า, กลไก Surprise Bag, การอ้างว่ามีร้านพร้อมขาย |
| [YAZIO](https://www.yazio.com/en) | หัวข้ออ่านเร็ว, ตัวเลขโภชนาการที่จัดกลุ่ม, navigation มี label, ภาพสแกนที่เป็นจุดโฟกัส | เป้าหมายลดน้ำหนัก, fasting, water tracker, streak/rewards, barcode และฟีเจอร์ใหม่ที่ไม่อยู่ในงานนี้ |
| [Lifesum](https://lifesum.com/) | โทนอุ่นแบบ editorial, ภาพมื้ออาหารพร้อมข้อมูลสรุป, ลำดับภาพ → รายละเอียดที่อ่านง่าย | claim สุขภาพ/ผลลัพธ์, chatbot/voice logging, การบันทึกอัตโนมัติโดยไม่ให้ผู้ใช้ยืนยัน |

ข้อเสนอทั้งสามเป็นการตีความหลักการจากหน้าที่เปิดดู ไม่คัดลอกหน้าจอ โลโก้ ภาพถ่าย หรือระบบของเว็บไซต์เหล่านี้ ภาพอาหารใน proposal เป็นภาพประกอบที่สร้างขึ้น ไม่ใช่ภาพจริงของร้านหรือภาพจาก Google Maps

## เปรียบเทียบสามแนวทาง

| | 01 Coral Flow | 02 Campus Pop | 03 Midnight Coral |
| --- | --- | --- | --- |
| บุคลิก | อบอุ่น ชัดเจน ใช้ทุกวันง่าย | สดใส มีเอกลักษณ์แบบ campus | โทนเข้ม เน้นภาพอาหารและความนิ่ง |
| จุดเด่น | ต่อจาก Coral Companion เดิมได้ตรงที่สุด | จดจำแบรนด์ได้แรงที่สุดในสามแบบ | อีกบรรยากาศหนึ่งที่ต่างจากแอปเดิมชัดเจน |
| รูปแบบ Top 3 | photo + details เป็น 3 rows เทียบกันเร็ว | featured card อันดับ 1 + compact cards อีก 2 | editorial list, photo strips + separators |
| จุดที่ต้องระวัง | อย่าเรียบจนกลายเป็น template ทั่วไป | คุมสีรอง/outline/ภาพตัดไม่ให้แย่ง CTA | ต้องเพิ่ม dark tokens และ QA รูป/แผนที่/ฟอร์มทุก state |
| ระดับความเปลี่ยนแปลง | ต่ำ–กลาง | กลาง | สูง หากทำเป็นอีก theme ทั้งแอป |

ระดับความเปลี่ยนแปลงเป็นการประเมินเชิงคุณภาพ ไม่ใช่ estimate เวลา/งบที่ยืนยันแล้ว

## 01 — Coral Flow

**แนวคิด:** เพื่อนเลือกมื้อที่อุ่นใจ อ่านเร็ว และให้ภาพอาหารมีน้ำหนักมากขึ้น เป็นทางเลือกหลักที่แนะนำสำหรับการปรับรอบถัดไป

สีหลัก: canvas `#FFFAF6`, ink `#29221F`, coral `#D82E50`, action `#B51F40`, blush `#FBE5E8`, secondary ink `#776960`

- Home: hero สั้น ภาพจานอาหารขนาดพอดี + card ตั้งค่ามื้อแบบรวม location / budget / preferences; budget ไม่ยึดพื้นที่ครึ่งหน้า
- Top 3: สามแถวที่มี thumbnail, ชื่อ, ราคาชัด, confidence label และ action ดูร้าน ใช้ coral outline เบา ๆ เฉพาะอันดับแรก
- Scan review: ภาพ preview, ส่วนประมาณอาหารและค่าพลังงานเด่น, macro ที่แก้ไขได้, กล่องแจ้งประมาณการแบบไม่ขู่
- หน้าร้าน: photo hero ที่มีที่มาจริง, แถวราคา/หลักฐาน, map section และเลือกมื้อที่ต้องยืนยัน ไม่เพิ่มปุ่มสั่งอาหาร
- บันทึก: สรุปวันนี้ใน white card และรายการมื้อที่อ่านเร็ว ไม่มีเป้าลดน้ำหนักใหม่
- Auth/settings: ฟอร์มสงบ error ใกล้ field และ privacy controls ตามระบบเดิม

**Tradeoff:** เสี่ยงต่ำกว่าแบบอื่นและเหมาะกับการใช้ประจำ แต่ต้องคุมภาพ/copy ให้มีบุคลิก ไม่ใช่เพียงย่อ card เดิม

## 02 — Campus Pop

**แนวคิด:** น่าจดจำแบบร้านอาหาร/นิตยสารของวัยมหาวิทยาลัย ไม่ทำให้แอปกลายเป็นเกม

สีหลัก: canvas `#FFF8E7`, ink `#24201F`, coral `#D82E50`, action `#B51F40`, butter yellow `#F6D86B`, soft lilac `#DCD5F4`

- Home: budget เป็น composition แบบกราฟิก ตัวเลขใหญ่ มีอาหารตัดฉากประกอบ โดย controls และ CTA ไม่ถูกภาพทับ
- Top 3: อันดับแรกเป็น featured photo card ที่กระชับ อีกสองอันดับเป็น compact rows เพื่อให้ยังเทียบครบได้
- Scan review: ภาพอาหารบนกรอบสีอุ่นและ nutrition 2×2 tiles แก้ไขได้ สีช่วยจัดกลุ่ม ไม่สื่อว่าอาหารดี/แย่
- หน้าร้าน: ภาพนำ + section labels ที่มีบุคลิก แต่ map และข้อมูลข้อจำกัดอาหารใช้รูปแบบชัดตรงไปตรงมา
- บันทึก: daily summary แบบ graphic tiles และรายการมื้อ ไม่เพิ่ม streak, rewards หรือ pressure ให้ใช้งาน
- Auth/settings: ลดความตกแต่งในฟอร์ม ใช้ภาษา/ตำแหน่ง error และ focus เดียวกับแบบหลัก

**Tradeoff:** เหมาะหากต้องการบุคลิกวัยรุ่นที่ชัด ต้องจำกัดสีรองและ decoration ไม่ให้กลบข้อมูลความปลอดภัย/ราคา

## 03 — Midnight Coral

**แนวคิด:** มื้อค่ำแบบ editorial ภาพอาหารเด่นบน charcoal; เป็นข้อเสนอ optional dark direction ไม่ใช่ระบบที่แอปมีครบแล้ว

สีหลัก: canvas `#18191D`, surface `#25262D`, warm text `#FFF5EB`, secondary `#BCB5AF`, accent/action `#FF7187`, border `#41424A`; โลโก้ยังคง coral เดิม

- Home: ภาพอาหารแบบกว้างบนพื้นเข้ม มี summary งบ/ตำแหน่งแบบกระชับ และ CTA coral ตัวอักษรสีเข้ม
- Top 3: ภาพ strip, เส้นแบ่งเบา ๆ และ typography เป็นตัวจัดลำดับ ไม่ใช้เงาหรือกรอบใหญ่ทุกชิ้น
- Scan review: calories เด่น + macro fields ที่มีขอบและ label แก้ไขได้; estimate note แยกชัดจากค่าที่ผู้ใช้ยืนยัน
- หน้าร้าน: สลับ photo / dark content sections; ต้องทดสอบ map contrast/branding แยก ห้ามคิดว่าการเปลี่ยน Flutter theme จะเปลี่ยน map โดยอัตโนมัติ
- บันทึก: neutral dark cards และรายการมื้อ ใช้ accent เฉพาะสิ่งที่เลือก/กดได้
- Auth/settings: keyboard, autofill, error, disabled, popup และ platform permissions ต้องตรวจใหม่ครบ

**Tradeoff:** สวยต่างและมีบรรยากาศมาก แต่ต้องมี token coverage/contrast/ภาพ placeholder ครบ จึงไม่แนะนำสลับทั้งแอปทันทีโดยไม่มีรอบ QA

## หลัก UX ที่เหมือนกันทั้งสามแบบ

- Bottom navigation คง **มื้อนี้ / บันทึก / สแกน** พร้อม icon และ label; account/settings เข้าผ่าน header ตามเดิม ไม่สร้าง tab หรือฟีเจอร์ที่ยังไม่มี
- Home มี action หลักหนึ่งรายการ เมื่อข้อมูลยังไม่ครบ action พาไป prerequisite ที่ขาด เมื่อครบจึงเปิด Top 3
- Budget quick chips เป็น draft; เปลี่ยนงบแล้วต้องเห็น pending state และกดยืนยันก่อนนำไปแนะนำ ภาพ proposal แสดง sample state ที่ยืนยัน 60 บาทแล้ว ไม่ได้อนุมัติ hidden auto-confirm
- สถานะ location ใช้ชื่อพื้นที่เฉพาะเมื่อมีข้อมูลรองรับ ไม่อนุมานชื่อจาก GPS เอง; ไม่แสดงพิกัดดิบหรือบันทึก location ใหม่เพื่อดีไซน์
- Distances ใน proposal เป็น **เส้นตรงโดยประมาณ** ไม่ใช่ระยะเดิน/เวลาเดินทางจริง
- Food preferences และ allergies ยังคง hard exclusions และ policy ของข้อมูลไม่ครบ ไม่ใช้ป้ายว่า “ปลอดภัยแน่นอน”
- แสดงราคา verified / estimated / unverified และวันที่/ที่มาตามข้อมูลจริง สีไม่ใช่สัญญาณเดียว
- ตัวเลขโภชนาการและผล AI เป็นค่าประมาณ แสดง portion assumption และแก้ไขก่อนบันทึก ห้ามวาด UI ที่สื่อผลแม่นยำหรือ AI บันทึกเอง
- บันทึก meal selection และ scan ต้องยืนยันตาม flow เดิม ป้องกัน double submit และแสดง pending / success / retry จริง
- ภาพร้าน/เมนูจริงต้องมี provenance และ attribution ตาม source; หากไม่มี ใช้ branded placeholder พร้อมคำว่า “ภาพประกอบ” ห้ามนำภาพ generated ใน proposal ไปอ้างเป็นภาพร้านจริง
- ไม่มี carousel autoplay, endless feed, ระบบสั่งอาหาร/จ่ายเงิน/Pro/rewards หรือ live requests เพิ่มจากงานเสนอครั้งนี้

## Typography / accessibility / states

- ใช้ **Prompt** สำหรับ headings, price emphasis และ actions; **Noto Sans Thai** สำหรับเนื้อหา/label/forms เพื่อใช้ font assets เดิม ไม่ต้องโหลดฟอนต์ใหม่
- แนวทางเริ่มต้น: page heading 28–32, section 20–22, body 16, secondary 14; ไม่ใช้ caption จิ๋วสำหรับข้อมูลตัดสินใจสำคัญ
- กริด 8px; light cards ประมาณ 20–24px, pop 18–20px, dark 16–20px; tap target อย่างน้อย 48 logical pixels
- เคารพ system text scale และ safe area; ถ้าพื้นที่ไม่พอให้เลื่อน/เปลี่ยน layout ไม่บีบ label จนอ่านไม่ได้ การเห็นครบ Top 3 ในภาพเสนอไม่ใช่เงื่อนไขบังคับให้ cram บนจอเล็ก
- เตรียม default / selected / focused / disabled / loading / error / empty / offline; motion ใช้เฉพาะ feedback และต้องไม่กวน reduced-motion preference
- จอ keyboard เปิดยังต้องแก้ field และเข้าถึงปุ่มบันทึกได้; ไม่วาง sticky CTA ทับ field/error
- Screen reader ต้องอ่านชื่อเมนู ราคา confidence และ estimate ได้อย่างเป็นลำดับ; rank/selection ไม่พึ่งสีอย่างเดียว

ค่าสีข้อความที่คำนวณสำหรับ token ที่เสนอ (ยังไม่ใช่ผล audit ทั้งแอป):

| Foreground / background | Contrast ratio |
| --- | --- |
| `#FFFFFF` / `#B51F40` | 6.49:1 |
| `#29221F` / `#FFFAF6` | 15.08:1 |
| `#776960` / `#FFFAF6` | 5.10:1 |
| `#24201F` / `#F6D86B` | 11.49:1 |
| `#FFF5EB` / `#18191D` | 16.32:1 |
| `#BCB5AF` / `#25262D` | 7.44:1 |
| `#18191D` / `#FF7187` | 6.66:1 |

ภาพ generated อาจเบี่ยงจาก hex/ฟอนต์/ข้อความที่ระบุ เมื่อ implement ให้ยึด token และ copy ที่ตรวจใน Flutter จริง ไม่ใช้ภาพเป็นข้อกำหนด pixel-perfect

## ข้อเสนอเลือกทิศทาง

แนะนำ **01 Coral Flow** เป็นฐาน: เหมาะกับแก่น budget-first, ใช้งานทุกวัน, และต่อยอดจาก theme/asset เดิมได้ตรง หากผู้ใช้ต้องการความวัยรุ่นโดดเด่นกว่า ให้เลือก **02 Campus Pop** เป็นระบบหลักที่คุมความตกแต่งแล้ว ส่วน **03 Midnight Coral** เหมาะเป็นทางเลือกโทนเข้มเมื่อพร้อมเพิ่ม theme QA

ผู้ใช้เลือก **02 Campus Pop** แล้ว โดยขอให้แก้โลโก้ก่อน การแนะนำ 01 ข้างต้นเป็นเหตุผล ณ รอบเสนอ ไม่ใช่ทิศทางล่าสุดที่เลือก ยังไม่ผสมทั้งสามเป็นระบบเดียวอัตโนมัติ และยังไม่ถือว่าภาพ raster เป็นข้อกำหนด pixel-perfect

## สถานะ implementation (2026-10-04)

เริ่มใช้ token ของ Campus Pop กับ theme ส่วนกลางแล้ว Home ย้ำงบที่ยืนยัน/อาหารที่กินได้และใช้ doodle อาหารแบบเวกเตอร์แทนภาพเมนูที่ไม่มีที่มา, Top 3 ใช้ featured card กับอันดับถัดไปแบบ compact, และ Food Scan แยกช่องประมาณโภชนาการเป็น 2×2 ที่แก้ไขได้ การ์ดที่ไม่มีภาพเมนูจริงยังคงข้อความ “ภาพประกอบ”; ไม่มีการนำภาพ generated ใน proposal มาแสดงเป็นข้อมูลร้าน

`flutter analyze --no-pub` และ Flutter tests ทั้ง 123 รายการผ่าน รวม layout จอ 320×640 ที่ 200% text. เปิด process ของ AVD แล้ว แต่ ADB ใน runner ปัจจุบันหยุดก่อนสั่งแอปเพราะหา Windows profile สำหรับ `.android` ไม่ได้ จึงยังไม่มีการติดตั้งแอปใหม่หรือ visual acceptance บน Emulator. ตามคำขอผู้ใช้ยังไม่สร้าง APK. หน้าร้าน/บันทึก/auth/settings และ visual QA ต่อหลังผู้ใช้ตรวจรอบแรก.
