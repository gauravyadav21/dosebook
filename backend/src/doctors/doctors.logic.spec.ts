import { type DoctorLike, matchDoctor, normalizeName, normalizePhone } from './doctor-match.js';
import { shareText } from './share-text.js';

const mehra: DoctorLike = { id: 'd1', name: 'Dr. A. Mehra', phone: '+91 00000 00101', registrationNo: 'MH-00000-DEMO' };
const iyer: DoctorLike = { id: 'd2', name: 'Dr. R. Iyer', phone: null, registrationNo: null };

describe('normalizeName', () => {
  it.each(['Dr. A. Mehra', 'dr a mehra', ' DR.  A.  MEHRA ', 'A. Mehra'])('treats "%s" as the same name', (name) => {
    expect(normalizeName(name)).toBe('a mehra');
  });
  it('does not strip "dr" inside a name', () => {
    expect(normalizeName('Andrew Drake')).toBe('andrew drake');
  });
});

describe('normalizePhone', () => {
  it('ignores spaces, dashes and brackets', () => {
    expect(normalizePhone('+91 (00000)-00101')).toBe('+910000000101');
  });
});

describe('matchDoctor', () => {
  it('matches on registration number whatever the name or letter case', () => {
    expect(matchDoctor({ name: 'Someone Else', registrationNo: ' mh-00000-demo ' }, [mehra, iyer])).toEqual({
      kind: 'EXACT',
      doctor: mehra,
    });
  });

  it('matches on name and phone together', () => {
    expect(matchDoctor({ name: 'dr a mehra', phone: '+91-00000-00101' }, [mehra, iyer])).toEqual({ kind: 'EXACT', doctor: mehra });
  });

  it('asks the user when only the name matches', () => {
    expect(matchDoctor({ name: 'Dr. A. Mehra' }, [mehra, iyer])).toEqual({ kind: 'NAME_ONLY', candidates: [mehra] });
    expect(matchDoctor({ name: 'Dr. A. Mehra', phone: '+91 00000 00999' }, [mehra])).toEqual({
      kind: 'NAME_ONLY',
      candidates: [mehra],
    });
  });

  it('does not match on phone alone', () => {
    expect(matchDoctor({ name: 'Dr. B. Rao', phone: '+91 00000 00101' }, [mehra])).toEqual({ kind: 'NONE' });
  });

  it('finds nothing among no cards', () => {
    expect(matchDoctor({ name: 'Dr. A. Mehra', registrationNo: 'MH-00000-DEMO' }, [])).toEqual({ kind: 'NONE' });
  });
});

describe('shareText', () => {
  it('lists only the details that exist', () => {
    expect(shareText({ name: 'Dr. S. Khan', specialty: 'Dentist', phone: null, registrationNo: null, availability: null })).toBe(
      'Dr. S. Khan\nDentist\nAs printed on a prescription. Not verified.',
    );
  });
  it('always says the details are not verified', () => {
    expect(shareText({ name: 'X', specialty: null, phone: null, registrationNo: null, availability: null })).toMatch(/Not verified/);
  });
});
