from pathlib import Path
p=Path('/mnt/data/aha_work/lib/main.dart')
s=p.read_text()
old="""              onTap: () async {\n                final uri = Uri.parse(algorithm.imageUrl);\n                await launchUrl(uri, mode: LaunchMode.externalApplication);\n              },"""
new="""              onTap: () {\n                Navigator.of(context).push(\n                  MaterialPageRoute(\n                    builder: (_) => AhaOfflineAlgorithmPage(algorithm: algorithm),\n                  ),\n                );\n              },"""
if old not in s: raise SystemExit('tap block not found')
s=s.replace(old,new,1)
marker='\n\n\nclass TranslatorPage extends StatefulWidget {'
page=r'''


class AhaOfflineAlgorithmPage extends StatelessWidget {
  final AhaAlgorithm algorithm;

  const AhaOfflineAlgorithmPage({super.key, required this.algorithm});

  static const Map<String, List<String>> _offlineSteps = {
    'Adult Basic Life Support — Healthcare Professionals': [
      'Verify scene safety and assess responsiveness.',
      'Activate the emergency response system and obtain an AED/defibrillator.',
      'Assess breathing and pulse; begin CPR when indicated.',
      'Provide high-quality chest compressions and ventilations according to current AHA guidance.',
      'Use the AED/defibrillator as soon as available and follow device prompts.',
      'Continue the resuscitation sequence and reassess according to the algorithm.'
    ],
    'Adult Basic Life Support — Lay Rescuers': [
      'Recognize suspected cardiac arrest and activate the emergency response system.',
      'Begin chest compressions promptly and obtain an AED when available.',
      'Use the AED and follow its prompts.',
      'Continue CPR until signs of life, trained rescuers take over, or the resuscitation is otherwise terminated.'
    ],
    'Adult Foreign-Body Airway Obstruction': [
      'Recognize mild versus severe foreign-body airway obstruction.',
      'For severe obstruction in a conscious adult, use the current AHA sequence of back blows and abdominal thrusts.',
      'If the patient becomes unresponsive, activate the emergency response system and begin CPR.',
      'Each time the airway is opened during CPR, look for a visible object and remove it if present; do not perform blind finger sweeps.'
    ],
    'Pediatric BLS — Single Rescuer': [
      'Assess responsiveness and breathing and activate the emergency response system as indicated.',
      'Check for a pulse when appropriate for the healthcare professional algorithm.',
      'Begin CPR when indicated and use an AED/defibrillator as soon as available.',
      'Follow the pediatric compression, ventilation, and rhythm-assessment sequence in the current AHA algorithm.',
      'Continue cycles of CPR and reassessment until return of circulation or termination of resuscitation.'
    ],
    'Pediatric BLS — 2 or More Rescuers': [
      'Assess the child or infant and activate the emergency response system.',
      'Assign roles and begin high-quality CPR when indicated.',
      'Use an AED/defibrillator as soon as available.',
      'Follow the pediatric 2-or-more-rescuer compression, ventilation, and rhythm sequence.',
      'Continue CPR and reassessment according to the current AHA algorithm.'
    ],
    'Infant FBAO': [
      'Recognize severe foreign-body airway obstruction in an infant.',
      'Use the current AHA sequence of repeated back blows and chest thrusts.',
      'If the infant becomes unresponsive, begin CPR and activate the emergency response system.',
      'Remove a visible object when encountered during airway assessment; do not perform blind finger sweeps.'
    ],
    'Child Foreign-Body Airway Obstruction': [
      'Recognize severe foreign-body airway obstruction in a child.',
      'Use the current AHA sequence of back blows and abdominal thrusts.',
      'If the child becomes unresponsive, begin CPR and activate the emergency response system.',
      'Remove a visible object when encountered during airway assessment; do not perform blind finger sweeps.'
    ],
    'Adult Cardiac Arrest — Circular Algorithm': [
      'Start with high-quality CPR and rapid rhythm assessment.',
      'For a shockable rhythm, deliver defibrillation and resume CPR promptly.',
      'For a nonshockable rhythm, continue CPR and address reversible causes.',
      'Use medications and advanced airway/ventilation strategies according to the current AHA ALS algorithm.',
      'Reassess rhythm at the appropriate intervals and continue until ROSC or termination criteria are met.'
    ],
    'Adult Cardiac Arrest': [
      'Begin high-quality CPR and obtain a monitor/defibrillator.',
      'Determine whether the rhythm is shockable or nonshockable.',
      'Treat VF/pVT with defibrillation and continued CPR; treat asystole/PEA with CPR and appropriate medications.',
      'Consider advanced airway and capnography when indicated.',
      'Identify and treat reversible causes and reassess rhythm at the designated intervals.',
      'If ROSC occurs, transition to post-cardiac-arrest care.'
    ],
    'BLS / Universal Termination of Resuscitation Rules': [
      'Use the rule only when its inclusion and criteria are applicable to the resuscitation setting.',
      'Confirm the required clinical and system-level criteria before considering termination.',
      'If termination criteria are not met, continue resuscitation and transport/medical control actions as required.',
      'Follow local medical direction and system policy in addition to the AHA rule.'
    ],
    'ALS Termination of Resuscitation Rule': [
      'Apply the rule only to patients and systems for which the ALS termination criteria are intended.',
      'Confirm all required clinical criteria and absence of exclusion conditions.',
      'If criteria are not satisfied, continue resuscitation and follow medical direction.',
      'Use local EMS policy and medical control requirements for any termination decision.'
    ],
    'Adult Tachyarrhythmia With a Pulse': [
      'Assess the airway, breathing, oxygenation, circulation, and monitor the rhythm.',
      'Determine whether the tachyarrhythmia is causing hemodynamic instability.',
      'For unstable tachyarrhythmia, use synchronized cardioversion when indicated.',
      'For stable patients, identify rhythm characteristics and use the appropriate medication/consultation pathway.',
      'Reassess continuously and address underlying causes.'
    ],
    'Electrical Cardioversion': [
      'Confirm the patient has a tachyarrhythmia requiring synchronized cardioversion.',
      'Prepare the monitor/defibrillator for synchronized mode and apply appropriate pads.',
      'Provide sedation/analgesia when appropriate and when it will not delay lifesaving therapy.',
      'Deliver the recommended synchronized shock for the rhythm and reassess.',
      'Escalate or repeat therapy according to the current AHA algorithm and clinical response.'
    ],
    'Adult Bradycardia With a Pulse': [
      'Assess airway, breathing, oxygenation, circulation, and obtain a rhythm.',
      'Determine whether the bradycardia is causing cardiopulmonary compromise.',
      'Treat reversible causes and provide supportive care.',
      'For persistent symptomatic bradycardia, follow the AHA pathway for atropine and pacing/vasoactive support as indicated.',
      'Reassess response continuously.'
    ],
    'Adult Post-Cardiac Arrest Care': [
      'After ROSC, stabilize airway, breathing, and circulation.',
      'Optimize oxygenation and ventilation and support appropriate blood pressure/perfusion.',
      'Obtain a 12-lead ECG and evaluate for an underlying cause.',
      'Consider indicated coronary, neurologic, temperature-management, and seizure-related evaluation/interventions.',
      'Continue structured post-cardiac-arrest care and reassessment.'
    ],
    'Pediatric Cardiac Arrest': [
      'Begin high-quality pediatric CPR and obtain a monitor/defibrillator.',
      'Determine whether the rhythm is shockable or nonshockable.',
      'For VF/pVT, defibrillate and resume CPR promptly; for asystole/PEA, continue CPR and treat reversible causes.',
      'Use weight-based medications and advanced airway/ventilation strategies according to the current AHA algorithm.',
      'Reassess rhythm at the appropriate intervals and transition to post-arrest care after ROSC.'
    ],
    'Pediatric Bradycardia With a Pulse': [
      'Assess airway, breathing, oxygenation, circulation, and obtain a rhythm.',
      'Determine whether the bradycardia is causing cardiopulmonary compromise.',
      'Support oxygenation/ventilation and treat the underlying cause.',
      'If compromise persists, follow the AHA pathway for CPR, epinephrine, atropine when appropriate, and pacing when indicated.',
      'Reassess continuously.'
    ],
    'Pediatric Tachyarrhythmia With a Pulse': [
      'Assess airway, breathing, oxygenation, circulation, and rhythm.',
      'Determine whether the tachyarrhythmia is causing cardiopulmonary compromise.',
      'For unstable tachyarrhythmia, follow the AHA synchronized cardioversion pathway.',
      'For stable tachyarrhythmia, identify the rhythm and follow the appropriate vagal/adenosine or consultation pathway.',
      'Reassess response and underlying causes.'
    ],
    'Adult and Pediatric Durable LVAD': [
      'Assess the patient while recognizing that usual pulse and blood-pressure findings may be unreliable with continuous-flow LVADs.',
      'Check the LVAD controller, power source, alarms, and driveline as appropriate.',
      'Determine whether the device is functioning and address correctable equipment or power problems.',
      'If the patient is in cardiac arrest or severe instability, follow the AHA LVAD resuscitation pathway and local specialty guidance.',
      'Consult the LVAD center/medical control when indicated.'
    ],
    'Cardiac Arrest in Pregnancy': [
      'Begin high-quality CPR and follow the standard adult cardiac-arrest sequence.',
      'Activate the obstetric/neonatal and resuscitation teams early.',
      'Address reversible causes and pregnancy-specific considerations.',
      'Perform indicated left uterine displacement and prepare for resuscitative delivery when criteria are met.',
      'Continue coordinated maternal and neonatal resuscitation according to the current AHA algorithm.'
    ],
    'Neonatal Resuscitation': [
      'Prepare for birth and perform the initial newborn assessment.',
      'Provide routine care when the newborn is breathing effectively and has good tone.',
      'If needed, initiate ventilation support and reassess heart rate.',
      'Escalate respiratory support and chest compressions according to the neonatal resuscitation pathway when indicated.',
      'Use umbilical vascular access and medications when indicated by the algorithm.',
      'Continue reassessment and transition to post-resuscitation care.'
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _offlineSteps[algorithm.title] ?? const <String>[];

    return Scaffold(
      appBar: const BaxterAppBar(),
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  algorithm.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Offline quick reference',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key sequence',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < steps.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: const Color(0xFF025EFF),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    steps[i],
                                    style: const TextStyle(fontSize: 16, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse(algorithm.imageUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Official AHA Flowchart'),
                ),
                const SizedBox(height: 10),
                Text(
                  'The quick reference above is available offline. The official AHA flowchart is opened from AHA online and requires an internet connection. Use current approved protocols and medical direction for patient care.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
'''
if marker not in s: raise SystemExit('marker not found')
s=s.replace(marker,page+marker,1)
p.write_text(s)
