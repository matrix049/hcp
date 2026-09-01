import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { toCsv } from '../src/modules/admin/export.service.js';

/**
 * The CSV is the deliverable a statistician actually opens, so the escaping
 * rules and the Excel-compatibility choices are worth pinning down: a silent
 * regression here corrupts an export nobody re-checks.
 */
describe('toCsv', () => {
  const table = {
    columns: ['id', 'Région', 'Observations'],
    rows: [['r1', 'Marrakech-Safi', 'RAS']],
  };

  it('starts with a UTF-8 BOM so Excel reads accents and Arabic', () => {
    assert.ok(toCsv(table).startsWith('﻿'));
    assert.ok(!toCsv(table, { bom: false }).startsWith('﻿'));
  });

  it('separates with semicolons by default, commas on request', () => {
    assert.match(toCsv(table), /id;Région;Observations/);
    assert.match(toCsv(table, { delimiter: ',' }), /id,Région,Observations/);
  });

  it('quotes a cell containing the delimiter', () => {
    const out = toCsv({ columns: ['a'], rows: [['x;y']] }, { bom: false });
    assert.match(out, /"x;y"/);
  });

  it('doubles embedded quotes rather than breaking the row', () => {
    const out = toCsv({ columns: ['a'], rows: [['say "hi"']] }, { bom: false });
    assert.match(out, /"say ""hi"""/);
  });

  it('keeps a newline inside one quoted cell', () => {
    const out = toCsv({ columns: ['a'], rows: [['line1\nline2']] }, { bom: false });
    assert.match(out, /"line1\nline2"/);
  });

  it('renders null and undefined as empty, never as the word null', () => {
    const out = toCsv({ columns: ['a', 'b'], rows: [[null, undefined]] }, { bom: false });
    assert.equal(out.split('\r\n')[1], ';');
  });

  it('ends every record with CRLF, as RFC 4180 requires', () => {
    assert.ok(toCsv(table, { bom: false }).endsWith('\r\n'));
  });
});
