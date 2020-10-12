# Vocabulary-v5.0 Release notes guide

This page helps to understand the structure of the [Vocabulary-v5.0 Release notes](https://github.com/OHDSI/Vocabulary-v5.0/releases).

***

### 1. Domain changes
* Provides the count of the concepts that were reassigned to a different Domain withing the OMOP vocabulary release.
* Mostly such sort of changes is applied when Domain assignment was corrected during the vocabulary refresh/maintenance, and sometimes due to changes in OMOP CDM conventions.
* The output is distributed by **vocabulary_id**, **old_domain_id**, **new_domain_id**.
* **Old_domain_id** stands for the concept's Domain in the previous vocabulary release.
* **New_domain_id** stands for the concept's Domain in the current vocabulary release.

***

### 2. Newly added concepts grouped by Vocabulary_id and Domain
* Provides the count of the concepts that were introduced to the OMOP vocabulary withing the OMOP vocabulary release.
* They may be:
1. new concept added to the existing vocabularies due to its new version release.
2. concepts of the new OMOPed vocabularies.
3. service concepts introduced to support OMOP CDM functioning (UCUM, Type Concept, RxNorm Extension).
* The output is distributed by **vocabulary_id**, **domain_id**.

***

### 3. Standard concept changes
* Provides the count of the concepts that were change their status withing the OMOP vocabulary release.
* Status may be:
1. Standard - meaning that concept is Standard (standard_concept = 'S') and mapped to itself with 'Maps to' link.
3. Classification - meaning that concept is Classification (standard_concept = 'C') and can be mapped (or not) to other Standard concept(s) with 'Maps to' link.
2. Non-standard with mapping - meaning that concept is non-Standard (standard_concept = NULL) and mapped to other Standard concept (or several concepts) with 'Maps to' link(s).
3. Non-standard without mapping - meaning that concept is non-Standard (standard_concept = NULL), and mapping to any other Standard concept is NOT provided.
* The output is distributed by **vocabulary_id**, **old_standard_concept**, **new_standard_concept**.
* **Old_standard_concept** stands for the concept's status in the previous vocabulary release.
* **New_standard_concept** stands for the concept's status in the current vocabulary release.

***

### 4. Newly added concepts and their standard concept status
* Provides the count and the status of the concepts that were introduced to the OMOP vocabulary withing the OMOP vocabulary release.
* Status may be:
1. Standard - meaning that concept is Standard (standard_concept = 'S') and mapped to itself with 'Maps to' link.
3. Classification - meaning that concept is Classification (standard_concept = 'C') and can be mapped (or not) to other Standard concept with 'Maps to' link.
2. Non-standard with mapping - meaning that concept is non-Standard (standard_concept = NULL) and mapped to other Standard concept (or several concepts) with 'Maps to' links.
3. Non-standard without mapping - meaning that concept is non-Standard (standard_concept = NULL), and mapping to any other Standard concept is NOT provided.
* The output is distributed by **vocabulary_id**, **new_standard_concept**.
* **New_standard_concept** stands for the concept's status.

***

### 5. Changes of concept mapping status grouped by target domain
* Provides the count of the concepts that were change their mapping status withing the OMOP vocabulary release.
* Mapping status may be:
1. No mapping - meaning that concept has NO mapping to Standard concept provided (no any valid 'Maps to' links).
2. New concept - meaning that concept was just introduced within the current vocabulary release.
3. Domain (e.g., Condition) or combination of Domains (e.g., Condition/Observation) - reflects the Domain of the concept(s) the current concept is mapped to.
* The output is distributed by **vocabulary_id* *, **Old target Domain/Status**, **New target Domain/Status**.
* **Old target Domain/Status** stands for the concept's mapping status in the previous vocabulary release.
* **New target Domain/Status** stands for the concept's mapping status in the current vocabulary release.

***

## F.A.Q.

**Q1**: Why do we have a high count of NDC codes with a "Non-standard without mapping"?

**A1**: NDC regularly publish a lot of concept, and for most of them mapping to RxNorm isn't provided. Fortunately, most of non-mapped concepts are NOT real drugs, but devices, vitamins, etc. OHDSI vocabulary team periodically improves NDC mappings on the request basis. [Here is the related Github issue](https://github.com/OHDSI/Vocabulary-v5.0/issues/100) for posting the requests.

***

**Q2**: Why do we introduce non-standard concepts into RxNorm Extension vocabulary?

**A2**: Not all the concepts introduced to the RxNorm Extension vocabulary are the actual drug concepts, i.e. product/form/ingredient. RxNorm Extension also includes auxiliary concepts that support the Drug Domain. These concept classes are: Brand Name, Dose Form, Supplier.

Read more about Drug Domain in wiki: 
* [Drug Domain](https://www.ohdsi.org/web/wiki/doku.php?id=documentation:vocabulary:drug)
* [International drug vocabulary implementation process](https://www.ohdsi.org/web/wiki/doku.php?id=implementation_international_drug_vocabulary)
* [RxNorm Extension - an OHDSI resource to represent international drugs](https://www.ohdsi.org/web/wiki/doku.php?id=documentation:international_drugs)






This [guide](https://github.com/OHDSI/Vocabulary-v5.0/wiki/Release-notes-guide) can provide you more background on how to read the release notes.