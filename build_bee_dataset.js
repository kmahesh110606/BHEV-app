const fs = require('fs');
const readline = require('readline');

async function convertCsv() {
  const rl = readline.createInterface({
    input: fs.createReadStream('bee_charging_stations.csv'),
    crlfDelay: Infinity
  });

  const stations = [];
  let isHeader = true;

  for await (const line of rl) {
    if (isHeader) {
      isHeader = false;
      continue;
    }
    // Simple CSV parser handling quotes
    const cols = [];
    let inQuotes = false;
    let current = '';
    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        cols.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    cols.push(current.trim());

    if (cols.length >= 10) {
      const lat = parseFloat(cols[8]);
      const lng = parseFloat(cols[9]);
      if (!isNaN(lat) && !isNaN(lng) && lat > 5 && lat < 38 && lng > 68 && lng < 98) {
        stations.push({
          id: cols[0] || 'BEE-' + stations.length,
          name: cols[1] || 'EV Station',
          cpo: cols[2] || 'BEE',
          ownership: cols[3] || 'Govt.',
          state: cols[4] || '',
          district: cols[5] || '',
          city: cols[6] || cols[5] || '',
          address: cols[7] || '',
          lat: parseFloat(lat.toFixed(6)),
          lng: parseFloat(lng.toFixed(6)),
          conns: parseInt(cols[10]) || 1,
          power: parseFloat(cols[11]) || 7.4
        });
      }
    }
  }

  console.log('Successfully processed valid Indian stations:', stations.length);
  fs.writeFileSync('assets/bee_stations_compact.json', JSON.stringify(stations));
  const sizeMb = (fs.statSync('assets/bee_stations_compact.json').size / (1024 * 1024)).toFixed(2);
  console.log('Wrote assets/bee_stations_compact.json (' + sizeMb + ' MB)');
}

convertCsv();
