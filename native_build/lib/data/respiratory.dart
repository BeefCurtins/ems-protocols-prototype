import '../models/protocol.dart';

const List<Protocol> respiratory_protocols = [
  Protocol(
    title: 'Respiratory Guidelines',
    category: 'Respiratory',    content: r'''Ambulance
           Respiratory
           Guidelines''',
  ),

  Protocol(
    title: 'Airway Management',
    category: 'Respiratory',    content: r'''Airway Management
1. If signs of respiratory difficulty, administer oxygen by Nasal Cannula @ 4lpm.
2. If Respiratory Distress or Hypoxia initiate CPAP as appropriate (see procedure). Mask with
   appropriate flow rate.
3. Ventilator support guidelines:
           Respiratory rate <10 or >30.
           Abnormal skin color, moisture or temp.
           Use of accessory muscles for ventilation.
           Utilize waveform capnography to assure Co2 @ <45 to >35
4. Consider: Heart rate <60 or > 100 as an underline cause.
5. If spontaneous breathing is absent, markedly compromised or patient is unconscious: (GCS
   <8)
           Open airway via head tilt chin lift method. Use jaw thrust in suspected c-spine
               injuries
           Insert oral or nasal airway and ventilate via BVM with supplemental O2
           Suction as needed
           Perform endotracheal intubation (pre-oxygenated).
           Use pulse oximetry/Capnography as a monitoring tool.
     Consider RSI if possible.
           Oxygenate in between unsuccessful attempts.
           Each attempt should not take more than 30 seconds.
           Use caution in head and facial injuries. * Protect c-spine in suspected
               cervical injuries.
6. In certain situations, consider RSI procedures for establishing and maintaining a patient
   Airway.
7. (See procedure). Time to hospital should not delay RSI.

Procedures/Skills/Medications
   EMT- Vital signs, SaO2, Oxygen, EKG
   PARAMEDIC- ALL''',
  ),

  Protocol(
    title: 'Asthma',
    category: 'Respiratory',    content: r'''Asthma

    1. General Supportive Care
    2. Humidified O2 if possible
    3. Utilize waveform capnography to assure Co2 @ <45 to >35 (Observe for “Sharkfin
       waveform)
    4. Albuterol updraft 2.5 mg pre-mix. May repeat in 15 minutes.
    5. If Respiratory Distress or Hypoxia initiate CPAP as appropriate (see procedure). Mask with
       appropriate flow rate.
    6. Cautiously consider Epinephrine 1:1,000 0.3-0.5 mg IM. May repeat in 15 minutes.

Consideration: Epinephrine is not first therapy of choice in most patients including COPD
Procedures/Skills/Medications
   EMT- Vital signs, SaO2, Oxygen, EKG
   PARAMEDIC- ALL''',
  ),

  Protocol(
    title: 'Capnography',
    category: 'Respiratory',    content: r'''Capnography

    1. Capnography should be used on all Respiratory Complaint patients, COPD patients and
       patients with head injuries.
    2. Document End Tidal CO2 in the run report.
    3. For COPD patients follow the oxygen therapy protocol and monitor the patient for CO2
       retention with the nasal cannula attachment.
    4. For head injury or suspected CVA patients, ventilate the patient maintaining CO2 levels
       between 35-45. ALL intubated patients (Use waveform Capnography!).
    5. Utilize to help assess SEPTIC pts. Capnometry readings of 25mm or less can confirm a
       SEPSIS dx.

Procedures/Skills/Medications
   EMT- Vital signs, SaO2, Oxygen, EKG
   PARAMEDIC- ALL''',
  ),

  Protocol(
    title: 'COPD',
    category: 'Respiratory',    content: r'''COPD

    1.   General Supportive Care
    2.   Obtain baseline O2 sat and CO2 readings
    3.   Administer O2 via N/C @ 2-3 Lpm as tolerated by patient.
    4.   Albuterol updraft 2.5 mg pre-mix. May repeat in 3-5 minutes as needed.
    5.   Patients with severe respiratory distress consider initiating CPAP if patient can
         maintain open airway with (GCS>10) and systolic BP > 90 mmHg.

Considerations:
  • Pts with SOB and associated other types of complaints, consider high flow O2 via mask
      (trauma, chest pain, etc.).

    Procedures/Skills/Medications
    EMT- Oxygen
    PARAMEDIC- Oxygen, Albuterol updraft, CPAP''',
  ),

  Protocol(
    title: 'CPAP',
    category: 'Respiratory',    content: r'''CPAP
    1. Assemble necessary equipment
              CPAP equipment, oxygen supply, pulse oximetry, cardiac monitor, bag
                valve mask, capnography, advance airway adjuncts.
    2. Prepare patient, explain procedure and be prepared to coach patient throughout procedure.
    3. Ensure adequate oxygen supply is available to ventilation device.
    4. Patient should be on continuous pulse oximetry/capnography.
    5. Place patient in seated position.
    6. Apply cardiac monitor if not already in place, assess V/S. (Do not attach to a
        flow monitor – must be a 50-psi source).
    7. Attach corrugated tubing to generator.
    8. Select appropriate size mask and attach mask to tubing.
    9. Attach CPAP valve to center hole of mask.
    10. When mask is ready and the patient is prepared, turn the on/off valve fully to the on position.
    11. Ensure gas is flowing, hold mask to patient's face, gently apply mask to assure good seal
        (check for air leaks). Secure mask via straps when all leaks are sealed.
    12. Monitor and document the patient's respiratory response to treatment.
    13. Check and document vital signs every 5 minutes.
    14. Continue to coach patient to keep mask in place and readjust as needed.
    15. In most cases, patient should improve in the first 5 minutes with CPAP, if not consider of
        pathologies and do not delay other therapies.
    16. If respiratory status deteriorates, remove device and consider positive pressure
        ventilation with or without endotracheal intubation.

Considerations:
    • CPAP therapy needs to be continuous, and should not be removed unless the patient cannot
       tolerate the mask or experiences continued or worsening respiratory failure.
    • Use CPAP with caution and FULL PPE (w/ Goggles) in those pts. presenting as infectious.
    • It is acceptable for an updraft to be delivered via CPAP.
    • CPAP should not be used in children less than 12 years of age.
    • Do not remove CPAP until hospital therapy is ready to be place on patient.
*Patient must be awake and able to tolerate mask. If questionable (GCS) go directly to
endotracheal intubation.
• Assure that receiving facility is aware that the pt is on CPAP

Procedures/Skills/Medications
   EMT- Vital signs, SaO2, Oxygen, EKG
   PARAMEDIC- ALL''',
  ),

  Protocol(
    title: 'Surgical Cricothyrotomy (Bougie Assisted)',
    category: 'Respiratory',    content: r'''Surgical Cricothyrotomy
                                 (BOUGIE ASSISTED SURGICAL CRICOTHYROTOMY)

Indications:
A life-threatening condition exists AND advanced airway management is indicated AND
you are unable to establish an airway or ventilate the patient by any other means.
Contraindications:
    1. Age < 12 years: for children a percutaneous needle cricothryrotomy with large angiocath
        is preferred surgical airway for anatomic reasons
    2. Absolute —Cricothyrotomy is absolutely contraindicated when the airway is
        maintainable through noninvasive means.
    3. In addition, Cricothyrotomy should not be performed when damage to the larynx, cricoid
        cartilage, or trachea preclude successful oxygenation and ventilation, for example:
    4. Laryngeal injury with known damage to cricoid cartilage (laryngeal fracture)
    5. Tracheal rupture
    6. Tracheal transection with distal tracheal retraction into the mediastinum
    7. Relative — Several relative contraindications arise in situations where anatomic
        distortion increases the risk of airway complications or where excessive bleeding may be
        encountered during Cricothyrotomy as follows:
    8. Anterior neck swelling (eg, angioedema, hematoma) that obscures anatomical landmarks
    9. Anatomic anomalies or distortion of the larynx and trachea (eg, repaired tracheal
        anomalies,       Hurler syndrome) (see "Mucopolysaccharidoses: Clinical features and
        diagnosis", section on 'Hurler syndrome')
    10. Bleeding disorder
However, in most instances, the benefit of securing an airway will outweigh the risk of
performing surgical cricothyrotomy in these circumstances.

Considerations:
*Given the rarity and relative unfamiliarity of this procedure it may be helpful to have a medical
consult on the phone during the procedure. Consider contacting base for all cricothyrotomy
procedures.
*Surgical cricothyrotomy is a difficult and hazardous procedure that is to be used only in
extraordinary circumstances as defined here. The reason for performing this procedure must be
documented and submitted for review to the EMS Medical Director within 24 hours.
*Surgical cricothyrotomy is to be performed only by paramedics trained in this procedure.
*An endotracheal tube introducer (“bougie”) facilitates this procedure and has the advantage of
additional confirmation of tube position and ease of endotracheal tube placement. If no bougie is
available the procedure may be performed without a bougie by introducing endotracheal tube or
tracheostomy tube directly into cricothyroid membrane.

Protocol:
Technique:
1. Position the patient supine, with in-line spinal immobilization if indicated. If cervical spine
injury not suspected, neck extension will improve anatomic view.

2. Using an aseptic technique (betadine/alcohol wipes), cleanse the area.
3. Standing on the left side of the patient, stabilize the larynx with the thumb and middle finger
of your left hand, and identify the cricothyroid membrane, typically 4 fingerbreadths below
mandible
4. Using a scalpel, make a 3 cm centimeter vertical incision 0.5 cm deep through the skin and
fascia, over the cricothyroid membrane. With finger, dissect the tissue and locate the cricothyroid
membrane.
5. Make a horizontal incision through the cricothyroid membrane with the scalpel blade oriented
caudal and away from the cords.
6. Insert the bougie curved-tip first through the incision and angled towards the patient’s feet. (If
no bougie available, use tracheal hook instrument to lift caudal edge of incision to facilitate
visualization and introduction of ETT directly into trachea and then skip to # 9).
7. Advance the bougie into the trachea feeling for “clicks” of tracheal rings and until “hangup”
when it cannot be advanced any further. This confirms tracheal position.
8. Advance a 6-0 endotracheal tube over the bougie and into the trachea. It is very easy to
place tube in right mainstem bronchus, so carefully assess for symmetry of breath sounds.
Remove bougie while stabilizing ETT ensuring it does not become dislodged
9. Ventilate with BVM and 100% oxygen
10. Confirm and document tracheal tube placement as with all advanced airways: ETCO2 as well
as clinical indicators e.g.: symmetry of breath sounds, rising pulse oximetry, etc.
11. Secure tube with ties
12. Observe for subcutaneous air, which may indicate tracheal injury or extra- tracheal tube
position
13. Continually reassess ventilation, oxygenation and tube placement.
Precautions:
• Success of procedure is dependent on correct identification of cricothyroid membrane
• Bleeding will occur, even with correct technique. Straying from the midline is dangerous
and likely to cause hemorrhage from the carotid or jugular vessels, or their branches.

Procedures/Skills/Medications
   EMT- Vital signs, SaO2, Oxygen, EKG
   PARAMEDIC- ALL''',
  ),

  Protocol(
    title: 'Needle Cricothyrotomy (PTV)',
    category: 'Respiratory',    content: r'''Needle Cricothyrotomy
                        (PercutaneousTranstrachealVentilation)
Indications:
A life-threatening condition exists AND advanced airway management is indicated AND
you are unable to establish an airway or ventilate the patient by any other means.
This is to be used almost exclusively for peds <12yo as the lung volume in adults will not
properly allow for expiration of CO2.

Contraindications:
Absolute — Needle Cricothyrotomy with Percutaneous Transtracheal Ventilation (PTV) is
absolutely contraindicated when the airway is maintainable through noninvasive means.
In addition, needle cricothyrotomy with PTV should not be performed when damage to the
larynx, cricoid cartilage, or trachea preclude successful oxygenation and ventilation via a
transtracheal catheter, for example:
    1. Laryngeal injury with known damage to cricoid cartilage (laryngeal fracture)
    2. Tracheal rupture
    3. Tracheal transection with distal tracheal retraction into the mediastinum
Relative — Several relative contraindications arise in situations where anatomic distortion
increases the risk of airway complications or where excessive bleeding may be encountered
during needle cricothyrotomy and PTV as follows:
    4. Anterior neck swelling (eg, angioedema, hematoma) that obscures anatomical landmarks
    5. Anatomic anomalies or distortion of the larynx and trachea (eg, repaired tracheal
    anomalies, Hurler syndrome) (see "Mucopolysaccharidoses: Clinical features and diagnosis",
    section on 'Hurler syndrome')
    6. Bleeding disorder
However, in most instances, the benefit of securing an airway will outweigh the risk of
performing needle cricothyrotomy in these circumstances.

Considerations:
   Given the rarity and relative unfamiliarity of this procedure it may be helpful to have a
      medical consult on the phone during the procedure. Consider contacting base for all
      cricothyrotomy procedures.
   Needle Cricothyrotomy is a difficult and hazardous procedure that is to be used only in
      extraordinary circumstances as defined here. The reason for performing this procedure
      must be documented and submitted for review to the EMS Medical Director within 24
      hours.
   Needle Cricothyrotomy is to be performed only by paramedics trained in this procedure.

Protocol:
Technique:
1. Use universal precautions and sterile technique. Cleanse the site.
2. Attach a 3- to 10-mL syringe with a few mL of saline to a 13 to 18 gauge IV catheter.
3. Enter the cricothyroid membrane in its inferior-central part, directing the needle caudally at an
angle of 30 to 45 degrees.

4. Advance the needle while continuously applying negative pressure on the syringe, until air
bubbles are seen
5. Advance the catheter forward off the needle until its hub rests at the skin surface & remove the
needle.
6. Hold the catheter firmly in place at all times
7. Connect the catheter to an ET tube/BVM connector from a 3.0 ET tube with the tube portion
removed (connected to a BVM and a source of 100 percent oxygen).
8. Give a few ventilations by delivering short bursts of gas to reconfirm placement
9. Secure the transtracheal catheter.
10. Begin regular ventilation with I:E ratio 1:4 and respiratory rate 10 to 12 breaths/min in the
patient without complete upper airway obstruction; in patients with complete airway obstruction:
I:E ratio 1:8 to 1:10 respiratory rate 5 to 6 breaths/min).
14. Establishment a more definitive airway.
Equipment
     Universal precautions (gown, cap, mask, eye protection, sterile gloves)
     Povidone iodine for site cleansing
     Sterile drape
     1 percent lidocaine without epinephrine in syringe for local anesthesia
     Three to 10 mL syringe filled with sterile saline

Catheter (large bore) — AVOID needleless safety catheters
    Infants and young children - 16- to 18-gauge IV catheters
    Adults and adolescents - 12- (ID 2.8 mm) to 16-gauge (ID 1.5 mm) IV catheters
       (angiocath) or 6 French transtracheal catheter

Bag-valve-mask connector options — If a bag-valve-mask will be used for patient ventilation,
then it should connect to the catheter using one of the following adapters:
     3 mL Luer lock syringe with plunger removed with 7.5 mm ID ETT connector
     3.0 mm ID endotracheal tube connector attached directly to the catheter
     2.5 mm ID ETT connector attached to cut off IV tubing with Luer lock end connected
         directly to the catheter

Oxygen tubing connector options — If oxygen tubing will be used to connect to the oxygen
source, then the clinician may use one of the following options:
    Direct connection of oxygen tubing to catheter
    Y connector
    Three-way stopcock
Precautions:
    Success of procedure is dependent on correct identification of cricothyroid membrane
    Bleeding will occur, even with correct technique. Straying from the midline is dangerous
        and likely to cause hemorrhage from the carotid or jugular vessels, or their branches.
    Retention of CO2 is a limiting factor to this treatment. Urgent Definitive airway
        correction will be critical to the outcome of this pt.

Procedures/Skills/Medications
   EMT- Vital signs, SaO2, Oxygen, EKG
   PARAMEDIC- ALL''',
  ),

  Protocol(
    title: 'RSI Guidelines',
    category: 'Respiratory',    content: r'''Rapid Sequence Intubation
Indications for Rapid Sequence Intubation (RSI):
   1. A need to gain definitive control of a patient’s airway
   2. Indications for RSI may include:
        Any patient in whom airway compromise is a real possibility before or during
          transport.
        Any patient in which breathing is not adequate and will likely require intubation prior
          to delivery to ER.
        Any patient who is unable to maintain an adequate O2 saturation of > 90%
          while breathing independently with non-invasive respiratory interventions.
        Patients with trauma related injuries GCS of 8 or less.
        Multi System Trauma affecting adequacy of ventilations.
        Altered mental status where loss of airway is inevitable.
   3. RSI will NOT be used in situations where cricothyrotomy would be difficult or
       impossible or in situations such as epiglottitis or partial airway obstruction.
   4. RSI is contraindicated for patients less than 8 years old in the state of Arkansas.
   5. Patients that are Older than 8 but under 16 MUST contact MEDICAL CONTROL.

Preparation:
   1. Assure patient needs RSI.
   2. Assess patient appearance, oropharynx, and neck anatomy to anticipate difficult
      intubation.
   3. Pre-oxygenate patient with 100% oxygen via NRB, or if possible, nasal cannula.
   4. Be certain you have a second means for an airway if intubation is unsuccessful. Assure that
      you have a backup plan for securing and maintain the airway.
       Have a King Airway Device ready in case intubation is unsuccessful.
       Assure you have a BVM device, Oral and Nasal airways available.
       Have available the cricothyrotomy Kit ready for use as a last resort.
       Have King Vision scope prepared.
   5. Assure all necessary equipment is available and functioning.
       Suction
       Oxygen
       Light Source (Laryngoscope)
       ET Tubes and stylets, consider using Bougie as stylet- Cuff intact and checked
       ETCO2 waveform capnography. THIS IS OUR GOLD STANDARD!!!
       Pulse Ox Device
       BVM with 100% oxygen & waveform ETCO2 attached.
       Rescue Devices immediately available (King airway and Cric Kit)

   6. Prepare all medications in correct dosages in syringes and have them ready (RSI Kit).

Ensure that NO contraindications exist for each individual medication in the sequence
prior to administration. Remember that succinylcholine carries multiple contraindications.
    Hx of Neuromuscular disease (MS, ALS, MD)
    Hx of paralysis (paraplegia or quadriplegia)
    Prolonged immobility
    Major burns or crush injuries > 24 hours up to 7 days
    Known hyperkalemia,
    Family Hx of Malignant hyperthermia
    Hx of glaucoma • Penetrating eye injury (Causes increased IOP)
    Organophosphate poisoning

Procedure:
   1. Pre-medication: (3 Minutes Prior To Laryngoscopy)
                  Pre-medication is deferred in the crash airway scenario which applies to
                   the " unresponsive and unconscious patients"
         a. Lidocaine 1.5 mg/kg IV push * (Consider for Tight Brain)

   2. Induction (Immediately Prior to Laryngoscope)
         a. Etomidate (Amidate) 30mg IV Push
                    Provides approximately 300 seconds of hypnotic sedation.
                    Anticipate nausea and vomiting if intubation is not successful.
                    Consider decreasing dose to 0.15 mg/kg IV push for patients with
                     hypotension.
                    Etomidate is deferred in the CRASH Airway scenario
         b. Succinylcholine (Annectine) 150mg IV Push
                    Provides complete skeletal muscle paralysis with adequate intubating
                     conditions usually within 30 - 45 seconds, and will continue for around 5 -
                     7 minutes.
                    If a contraindication to succinylcholine exists, consider use of Rocuronium
                     100mg for paralysis.
         c. Apply GENTLE cricoid pressure to mitigate passive regurgitation simultaneously
             with paralytic administration until ETT confirmation and cuff inflation.

   3. Intubation:
         a. Positioning
                   Trauma: Consider King Vision Scope, and consider removal of
                    cervical collars and application of manual C-Spine control by an
                    assistant to increase jaw mobility and improve intubating conditions.

                        Medical: Place patient in sniffing position by elevating head with pillow
                         or towels.
           b.   Cricoid pressure continued throughout procedure.
           c.   Perform laryngoscopy and intubate the trachea.
           d.   Inflate ET cuff
           e.   Confirm placement (uses multiple methods listed)
                        Direct visualization of passage of ET through the vocal cords.
                        Lung sounds present and equal to pre-intubation conditions, and absent
                         sounds over epigastrium.
                        Chest rise and fall with ventilations, equal to pre-intubation conditions.
                        Carbon dioxide present with waveform capnography (35-45 mmHg).
                        Stat-Cap colorimetric device change to appropriate color per manufactures
                         recommendations
                        SpO2 evaluation
                        Have second qualified person confirm correct tube placement
           f.   Remove cricoid pressure.
           g.   Note and record ET depth at teeth.
           h.   Secure ET using commercial device.
           i.   If intubation attempts are unsuccessful: (2 attempts)
                        A secondary airway device such as a King airway device will be
                         attempted immediately. Ventilations will be maintained with a BVM
                         device and in conjunction with an OPA or NPA as needed.
                        In the event a patient cannot be ventilated by ANY OTHER MEANs
                         listed, perform a surgical cricothyrotomy. (Refer to Surgical
                         Cricothyrotomy Guidelines)

    4. Post - Intubation management
        a. Midazolam (Versed) 2.5 mg slow IV Push q 2 minutes titrated to effect or
            systolic BP of > 90mmHg.
                   Total dose is not to exceed 10 mg. If more than 10 mg is needed medical
                    control must be contacted.
        b. Rocuronium 100mg IV push
                   Used for ongoing paralysis, if required. (e.g. extended transport times).
        c. Fentanyl 50 mcg over 5min for sedation, always administer at least 1 dose
            post intubation.
        d. Contact medical control for pain management guidelines for post - intubation pain
            control.
Competency:
  1. Each individual paramedic that performs a RSI is required to complete a PCR and
     applicable RSI forms. All RSI records will be reviewed by our Ambulance Medical
     Director with follow up given in each case.
  2. Each individual Paramedic that performs RSI is required to complete the RSI training
     program, have the RSI sign off sheet signed and on file and adhere to guidelines set forth
     by BRMC and by the Arkansas State Department of Health.

   3. To assure continued proficiency in all aspects of RSI all paramedics selected to perform
      these procedures will be required to complete regular training made available through
      (monthly review, skill management workshops, and scheduled times in either ER or
      Surgery. Paramedics will be required to meet the following criteria annually.
           Cleared by Medical Director to perform RSI procedures in the field setting
              (requires minimum of one years’ experience as a field paramedic in addition to
              any criteria set forth by medical director).
           Documentation of 12 successful intubations annually in any of the three settings
              (ER, Surgery, Ambulance).
           Documentation of regular attendance at skills workshops and scheduled meetings
              that will include RSI training.

Crashed airway:
       Set dose to be given for RSI in a crashed airway scenario with no gag reflex. Follow
prep procedures, only 2 attempts with ET before going to King airway.
    Lidocaine 100mg (Use for possible Head Trauma or increased ICP)
    Etomidate 30mg
    Succinylcholine 150mg
    Rocuronium 100mg
    Versed 2-10mg slow IV, titrated to sedation.

 Procedures/Skills/Medications
    EMT- Vital signs, SaO2, Oxygen, EKG
    PARAMEDIC- ALL (ONLY Medical Director approved medics may utilize this procedure)''',
  ),

];
