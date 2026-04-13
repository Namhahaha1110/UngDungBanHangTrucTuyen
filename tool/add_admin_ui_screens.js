const fs = require('fs');
const path = require('path');

const {
  parseFig,
  encodeFigParts,
  assembleCanvasFig,
  createFigZip,
} = require('../_fig_tools/node_modules/openfig-core/dist/index.cjs');
const { ZstdCodec } = require('../_fig_tools/node_modules/zstd-codec');

const ROOT = path.resolve(__dirname, '..');
const FIG_PATH = path.join(ROOT, 'UngDungBanHang.fig');
const BACKUP_PATH = path.join(ROOT, 'UngDungBanHang.backup-admin-20260330.fig');
const UI_PAGE_ID = '1:97';
const SESSION_ID = 1;
const PRIMARY = '#FF6B00';
const BORDER = '#E0E0E0';
const TEXT = '#1A1A1A';
const WHITE = '#FFFFFF';
const LIGHT = '#F6F6F6';

function deepClone(value) {
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Uint8Array) return value.slice();
  if (value instanceof ArrayBuffer) return value.slice(0);
  if (Array.isArray(value)) return value.map(deepClone);
  const result = {};
  for (const key of Object.keys(value)) {
    result[key] = deepClone(value[key]);
  }
  return result;
}

function nodeId(node) {
  return `${node.guid.sessionID}:${node.guid.localID}`;
}

function parseId(id) {
  const [sessionID, localID] = id.split(':').map(Number);
  return { sessionID, localID };
}

function positionChar(index) {
  return String.fromCharCode(0x21 + index);
}

function hexToColor(hex) {
  const clean = hex.replace('#', '');
  const int = Number.parseInt(clean, 16);
  return {
    r: ((int >> 16) & 255) / 255,
    g: ((int >> 8) & 255) / 255,
    b: (int & 255) / 255,
    a: 1,
  };
}

function solidPaint(hex, opacity = 1) {
  return [
    {
      type: 'SOLID',
      color: hexToColor(hex),
      opacity,
      visible: true,
      blendMode: 'NORMAL',
    },
  ];
}

function rebuildMaps(doc) {
  doc.nodeMap = new Map();
  doc.childrenMap = new Map();
  for (const node of doc.message.nodeChanges) {
    if (!node.guid) continue;
    doc.nodeMap.set(nodeId(node), node);
  }
  for (const node of doc.message.nodeChanges) {
    if (!node.parentIndex?.guid) continue;
    const parentId = `${node.parentIndex.guid.sessionID}:${node.parentIndex.guid.localID}`;
    if (!doc.childrenMap.has(parentId)) {
      doc.childrenMap.set(parentId, []);
    }
    doc.childrenMap.get(parentId).push(node);
  }
}

function createGuidFactory(doc) {
  let maxLocalId = 0;
  for (const node of doc.message.nodeChanges) {
    if (node.guid?.localID > maxLocalId) {
      maxLocalId = node.guid.localID;
    }
  }
  return () => ({ sessionID: SESSION_ID, localID: ++maxLocalId });
}

function collectSubtree(doc, rootId) {
  const result = [];
  const walk = (id) => {
    const node = doc.nodeMap.get(id);
    if (!node || node.phase === 'REMOVED') return;
    result.push(node);
    for (const child of doc.childrenMap.get(id) || []) {
      walk(nodeId(child));
    }
  };
  walk(rootId);
  return result;
}

function activeChildren(doc, parentId) {
  return (doc.childrenMap.get(parentId) || []).filter((child) => child.phase !== 'REMOVED');
}

function cloneSubtree(doc, makeGuid, sourceRootId, targetParentId, position, options = {}) {
  const nodes = collectSubtree(doc, sourceRootId);
  const parentGuid = parseId(targetParentId);
  const idMap = new Map();
  for (const sourceNode of nodes) {
    idMap.set(nodeId(sourceNode), makeGuid());
  }
  const siblingIndex = activeChildren(doc, targetParentId).length;

  for (const sourceNode of nodes) {
    const sourceId = nodeId(sourceNode);
    const clone = deepClone(sourceNode);
    clone.guid = deepClone(idMap.get(sourceId));

    if (sourceId === sourceRootId) {
      clone.parentIndex = {
        guid: deepClone(parentGuid),
        position: positionChar(siblingIndex),
      };
      clone.transform = {
        ...(clone.transform || { m00: 1, m01: 0, m10: 0, m11: 1 }),
        m00: clone.transform?.m00 ?? 1,
        m01: clone.transform?.m01 ?? 0,
        m10: clone.transform?.m10 ?? 0,
        m11: clone.transform?.m11 ?? 1,
        m02: position.x,
        m12: position.y,
      };
      if (options.name) {
        clone.name = options.name;
      }
    } else if (clone.parentIndex?.guid) {
      const oldParentId = `${clone.parentIndex.guid.sessionID}:${clone.parentIndex.guid.localID}`;
      if (idMap.has(oldParentId)) {
        clone.parentIndex.guid = deepClone(idMap.get(oldParentId));
      }
    }

    if (clone.overrideKey) {
      const oldOverrideId = `${clone.overrideKey.sessionID}:${clone.overrideKey.localID}`;
      if (idMap.has(oldOverrideId)) {
        clone.overrideKey = deepClone(idMap.get(oldOverrideId));
      }
    }

    if (Array.isArray(clone.symbolOverrides)) {
      for (const override of clone.symbolOverrides) {
        if (!override.guidPath?.guids) continue;
        override.guidPath.guids = override.guidPath.guids.map((guid) => {
          const oldGuidId = `${guid.sessionID}:${guid.localID}`;
          return idMap.has(oldGuidId) ? deepClone(idMap.get(oldGuidId)) : guid;
        });
      }
    }

    doc.message.nodeChanges.push(clone);
  }

  rebuildMaps(doc);

  const clonedRootId = `${idMap.get(sourceRootId).sessionID}:${idMap.get(sourceRootId).localID}`;
  return { rootId: clonedRootId, idMap };
}

function cloneNodeOnly(doc, makeGuid, sourceId, targetParentId, position, options = {}) {
  const source = doc.nodeMap.get(sourceId);
  if (!source) {
    throw new Error(`Missing source node: ${sourceId}`);
  }
  const clone = deepClone(source);
  clone.guid = makeGuid();
  clone.parentIndex = {
    guid: deepClone(parseId(targetParentId)),
    position: positionChar(activeChildren(doc, targetParentId).length),
  };
  clone.transform = {
    ...(clone.transform || { m00: 1, m01: 0, m10: 0, m11: 1 }),
    m00: clone.transform?.m00 ?? 1,
    m01: clone.transform?.m01 ?? 0,
    m10: clone.transform?.m10 ?? 0,
    m11: clone.transform?.m11 ?? 1,
    m02: position.x,
    m12: position.y,
  };
  if (options.name) {
    clone.name = options.name;
  }
  doc.message.nodeChanges.push(clone);
  rebuildMaps(doc);
  return nodeId(clone);
}

function getNode(doc, id) {
  const node = doc.nodeMap.get(id);
  if (!node) {
    throw new Error(`Node not found: ${id}`);
  }
  return node;
}

function getMappedId(idMap, sourceId) {
  const guid = idMap.get(sourceId);
  if (!guid) {
    throw new Error(`Mapped node missing for source ${sourceId}`);
  }
  return `${guid.sessionID}:${guid.localID}`;
}

function setText(doc, idMap, sourceId, text) {
  const node = getNode(doc, getMappedId(idMap, sourceId));
  node.textData = {
    ...(node.textData || {}),
    characters: text,
  };
}

function hideNode(doc, idMap, sourceId) {
  const node = getNode(doc, getMappedId(idMap, sourceId));
  node.phase = 'REMOVED';
}

function setFill(node, hex, opacity = 1) {
  node.fillPaints = solidPaint(hex, opacity);
}

function setStroke(node, hex, opacity = 1) {
  node.strokePaints = solidPaint(hex, opacity);
}

function setTextColor(doc, idMap, sourceId, hex, opacity = 1) {
  const node = getNode(doc, getMappedId(idMap, sourceId));
  setFill(node, hex, opacity);
}

function replaceTextInSubtree(doc, rootId, matcher, replacement) {
  const queue = [rootId];
  while (queue.length > 0) {
    const currentId = queue.shift();
    const node = doc.nodeMap.get(currentId);
    if (!node || node.phase === 'REMOVED') continue;
    if (node.type === 'TEXT' && typeof node.textData?.characters === 'string') {
      if (matcher(node.textData.characters)) {
        node.textData.characters = replacement(node.textData.characters);
      }
    }
    for (const child of doc.childrenMap.get(currentId) || []) {
      queue.push(nodeId(child));
    }
  }
}

function addTextClone(doc, makeGuid, sourceTextId, parentId, position, text, hex, name) {
  const textId = cloneNodeOnly(doc, makeGuid, sourceTextId, parentId, position, { name });
  const node = getNode(doc, textId);
  node.textData = {
    ...(node.textData || {}),
    characters: text,
  };
  if (hex) {
    setFill(node, hex, 1);
  }
  return textId;
}

function removeExistingAdminFrames(doc) {
  for (const child of activeChildren(doc, UI_PAGE_ID)) {
    if (child.type === 'FRAME' && typeof child.name === 'string' && child.name.startsWith('Admin - ')) {
      child.phase = 'REMOVED';
    }
  }
  rebuildMaps(doc);
}

function buildDashboard(doc, makeGuid) {
  const { rootId, idMap } = cloneSubtree(doc, makeGuid, '6:104', UI_PAGE_ID, { x: 8200, y: -19 }, {
    name: 'Admin - Tổng quan',
  });
  hideNode(doc, idMap, '16:453');
  setText(doc, idMap, '50:238', 'Lối tắt quản trị');
  setText(doc, idMap, '50:236', 'Xem báo cáo');
  setText(doc, idMap, '50:351', 'Đơn mới hôm nay');
  setText(doc, idMap, '82:3077', 'Sản phẩm cần xử lý');

  addTextClone(doc, makeGuid, '70:192', rootId, { x: 20, y: 118 }, 'Admin Center', WHITE, 'Admin Dashboard Title');
  addTextClone(
    doc,
    makeGuid,
    '50:236',
    rootId,
    { x: 20, y: 156 },
    '24 đơn chờ xác nhận  |  12,4 triệu doanh thu',
    WHITE,
    'Admin Dashboard Subtitle',
  );
  addTextClone(
    doc,
    makeGuid,
    '50:236',
    rootId,
    { x: 20, y: 186 },
    '4 sản phẩm sắp hết hàng  |  2 chiến dịch sắp chạy',
    WHITE,
    'Admin Dashboard KPI',
  );

  rebuildMaps(doc);
  return rootId;
}

function buildProducts(doc, makeGuid) {
  const { rootId, idMap } = cloneSubtree(doc, makeGuid, '16:748', UI_PAGE_ID, { x: 8856, y: -19 }, {
    name: 'Admin - Sản phẩm',
  });
  hideNode(doc, idMap, '82:2714');
  setText(doc, idMap, '116:1868', 'Sản phẩm');
  setText(doc, idMap, '112:1860', 'Tất cả');
  setText(doc, idMap, '112:1861', 'Đang bán');
  setText(doc, idMap, '112:1865', 'Tạm ẩn');
  setText(doc, idMap, '116:1881', 'Danh mục');

  replaceTextInSubtree(doc, rootId, (value) => value.trim() === 'Tìm sản phẩm', () => 'Sửa');
  replaceTextInSubtree(doc, rootId, (value) => value.trim() === 'Yêu thích', () => 'Đang bán');
  replaceTextInSubtree(doc, rootId, (value) => value.trim() === 'Đã bán 1k+', () => 'Kho: 128');

  const addButton = cloneSubtree(doc, makeGuid, '177:2331', rootId, { x: 322, y: 84 }, { name: 'Thêm sản phẩm' });
  const addButtonRoot = getNode(doc, addButton.rootId);
  setFill(addButtonRoot, PRIMARY, 1);
  setStroke(addButtonRoot, PRIMARY, 1);
  setText(doc, addButton.idMap, '177:2332', '+ Thêm');
  setTextColor(doc, addButton.idMap, '177:2332', WHITE, 1);

  rebuildMaps(doc);
  return rootId;
}

function buildOrders(doc, makeGuid) {
  const { rootId, idMap } = cloneSubtree(doc, makeGuid, '16:755', UI_PAGE_ID, { x: 9512, y: -19 }, {
    name: 'Admin - Đơn hàng',
  });
  setText(doc, idMap, '215:2028', 'Đơn hàng');
  setText(doc, idMap, '215:2034', 'Đơn #SP-2048');
  setText(doc, idMap, '215:2036', 'Khách: Ngô Bá Khá');
  setText(doc, idMap, '215:2044', '431/71/1a Hà Thanh Lộc, Quận 12, TP.Hồ Chí Minh');
  setText(doc, idMap, '215:2055', 'Khách hàng');
  setText(doc, idMap, '215:2057', 'Ngô Bá Khá');
  setText(doc, idMap, '215:2059', '(+84) 913456798');
  setText(doc, idMap, '215:2061', 'Áo Phông Trơn Trắng');
  setText(doc, idMap, '215:2083', 'Chờ xác nhận');
  setText(doc, idMap, '215:2086', 'Mã đơn: SP-2048');
  setText(doc, idMap, '215:2088', 'Đen, Size L');
  setText(doc, idMap, '215:2089', '103.000đ');
  setText(doc, idMap, '215:2091', 'x1');
  setText(doc, idMap, '215:2094', 'Trạng thái đơn');
  setText(
    doc,
    idMap,
    '215:2093',
    'Đơn mới tạo lúc 09:24. Cần xác nhận trước 12:00 để chuẩn bị giao.',
  );
  setText(doc, idMap, '215:2106', 'Ghi chú khách hàng');
  setText(doc, idMap, '215:2111', 'Giao giờ hành chính');
  setText(doc, idMap, '215:2117', 'Vận chuyển');
  setText(doc, idMap, '215:2119', 'Chi tiết');
  setText(doc, idMap, '215:2124', 'Nhanh');
  setText(doc, idMap, '215:2125', 'Dự kiến 31 Th03 - 02 Th04');
  setText(doc, idMap, '215:2126', 'Phí giao hàng đã được người mua thanh toán');
  setText(doc, idMap, '215:2127', 'Theo dõi');
  setText(doc, idMap, '215:2132', 'Thanh toán');
  setText(doc, idMap, '215:2133', 'Biên nhận');
  setText(doc, idMap, '215:2136', 'ShoppePay');
  setText(doc, idMap, '215:2141', 'Đã thanh toán');
  setText(doc, idMap, '215:2150', 'Cập nhật trạng thái');

  rebuildMaps(doc);
  return rootId;
}

function buildEditor(doc, makeGuid) {
  const { rootId, idMap } = cloneSubtree(doc, makeGuid, '16:751', UI_PAGE_ID, { x: 10168, y: -19 }, {
    name: 'Admin - Chỉnh sửa SP',
  });
  hideNode(doc, idMap, '137:1805');
  addTextClone(doc, makeGuid, '215:2028', rootId, { x: 146, y: 58 }, 'Chỉnh sửa SP', TEXT, 'Editor Title');

  setText(doc, idMap, '124:1971', 'Lưu nháp');
  setText(doc, idMap, '137:1843', 'Xuất bản');
  setText(doc, idMap, '177:2330', 'Lưu nháp');
  setText(doc, idMap, '177:2332', 'Xuất bản');
  setText(doc, idMap, '124:1984', 'THÔNG TIN CƠ BẢN');
  setText(doc, idMap, '124:1987', 'Danh mục');
  setText(doc, idMap, '124:1989', 'Thời trang > Nam > Quần jeans');
  setText(doc, idMap, '124:1990', 'Biến thể');
  setText(doc, idMap, '124:1991', '30-41 / Xanh');
  setText(doc, idMap, '124:1995', 'Tồn kho');
  setText(doc, idMap, '124:1996', '128 sản phẩm');
  setText(doc, idMap, '124:1997', 'SKU');
  setText(doc, idMap, '124:1998', 'JEANS-WN-001');
  setText(doc, idMap, '124:2001', 'MÔ TẢ SẢN PHẨM');
  setText(doc, idMap, '124:2002', 'Ảnh tham chiếu');

  const draftButton = getNode(doc, getMappedId(idMap, '177:2329'));
  setFill(draftButton, LIGHT, 1);
  setStroke(draftButton, BORDER, 1);
  setTextColor(doc, idMap, '177:2330', TEXT, 1);

  const publishButton = getNode(doc, getMappedId(idMap, '177:2331'));
  setFill(publishButton, PRIMARY, 1);
  setStroke(publishButton, PRIMARY, 1);
  setTextColor(doc, idMap, '177:2332', WHITE, 1);

  const topDraftButton = getNode(doc, getMappedId(idMap, '137:1841'));
  setFill(topDraftButton, LIGHT, 1);
  setStroke(topDraftButton, BORDER, 1);
  setTextColor(doc, idMap, '124:1971', TEXT, 1);

  const topPublishButton = getNode(doc, getMappedId(idMap, '137:1842'));
  setFill(topPublishButton, PRIMARY, 1);
  setStroke(topPublishButton, PRIMARY, 1);
  setTextColor(doc, idMap, '137:1843', WHITE, 1);

  rebuildMaps(doc);
  return rootId;
}

function encodeFig(doc) {
  return new Promise((resolve, reject) => {
    const parts = encodeFigParts(doc);
    ZstdCodec.run((zstd) => {
      try {
        const z = new zstd.Simple();
        const messageCompressed = z.compress(parts.messageRaw, 3);
        const canvasFig = assembleCanvasFig({
          prelude: parts.prelude,
          version: parts.version,
          schemaCompressed: parts.schemaCompressed,
          messageCompressed,
          passThrough: parts.passThrough,
        });
        const zipped = createFigZip({
          canvasFig,
          meta: doc.meta,
          thumbnail: doc.thumbnail,
          images: doc.images,
        });
        resolve(zipped);
      } catch (error) {
        reject(error);
      }
    });
  });
}

async function main() {
  if (!fs.existsSync(FIG_PATH)) {
    throw new Error(`Missing fig file: ${FIG_PATH}`);
  }

  if (!fs.existsSync(BACKUP_PATH)) {
    fs.copyFileSync(FIG_PATH, BACKUP_PATH);
  }

  const input = fs.readFileSync(FIG_PATH);
  const doc = parseFig(input);
  rebuildMaps(doc);

  removeExistingAdminFrames(doc);

  const makeGuid = createGuidFactory(doc);
  buildDashboard(doc, makeGuid);
  buildProducts(doc, makeGuid);
  buildOrders(doc, makeGuid);
  buildEditor(doc, makeGuid);

  rebuildMaps(doc);

  const encoded = await encodeFig(doc);
  fs.writeFileSync(FIG_PATH, Buffer.from(encoded));

  const verifyDoc = parseFig(fs.readFileSync(FIG_PATH));
  rebuildMaps(verifyDoc);
  const adminFrames = activeChildren(verifyDoc, UI_PAGE_ID)
    .filter((node) => node.type === 'FRAME' && typeof node.name === 'string' && node.name.startsWith('Admin - '))
    .map((node) => ({
      id: nodeId(node),
      name: node.name,
      x: node.transform?.m02 ?? 0,
      y: node.transform?.m12 ?? 0,
      width: node.size?.x ?? 0,
      height: node.size?.y ?? 0,
    }));

  console.log(JSON.stringify({ backup: BACKUP_PATH, adminFrames }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
