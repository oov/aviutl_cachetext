-- CacheText $VERSION$ ( $GITHASH$ ) by oov
local P = {}
local Extram = require('Extram')

P.caches = {}

P.creating = false
P.beforekey = nil
P.key = nil
P.msg = nil

function P.del(key)
  if P.caches[key] ~= nil then
    for i = 0, P.caches[key].num do
      Extram.del(key .. "-" .. i)
    end
  end
  P.caches[key] = nil
end

-- message: メッセージ本文
-- mode: 動作モード 0 = 常に最新データを使う / 1 = キャッシュを使う
function P.mes(message, mode)
  -- 拡張編集の GUI 上で入力されたテキストは Shift_JIS の駄目文字への対策が行われるが、
  -- そもそも文字列をダブルクォートで括っていない場合にはゴミになるので除去しておく
  return P.rawmes(message:gsub("([\128-\160\224-\255]\092)\092","%1"), mode)
end

function P.rawmes(message, mode)
  P.gc()

  P.beforekey = nil
  P.key = "CacheText:" .. obj.layer
  P.msg = message
  local c = P.caches[P.key]
  if (c ~= nil and c.msg ~= P.msg)or(mode == 0) then
    -- テキスト内容が変わったか、キャッシュ無効モードならキャッシュを破棄
    P.del(P.key)
    c = nil
  end
  if c == nil then
    mes(P.msg)
    P.creating = true
  else
    mes("<s1,Arial>" .. string.rep(".", c.num))
    P.creating = false
  end
end

function P.after()
  if P.key ~= nil then
    if P.creating then
      P.store(P.key)
    else
      P.load(P.key)
    end
    P.beforekey = P.key
    P.key = nil
    return
  end
  if P.beforekey ~= nil and obj.index > 0 then
    if P.creating then
      P.store(P.beforekey)
    else
      P.load(P.beforekey)
    end
    return
  end
end

function P.store(key)
  -- キャッシュ作成
  local w, h = 0, 0
  if obj.w ~= 0 and obj.h ~= 0 then
    -- 画像データがありそうならキャッシュに書き込む
    local data
    data, w, h = obj.getpixeldata()
    Extram.put(key .. "-" .. obj.index, data, w * 4 * h)
  end
  local c = P.caches[key]
  if obj.index == 0 then
    c = {
      t = os.clock(),
      d = 0,
      msg = P.msg,
      num = obj.num,
      img = {},
    }
  end
  c.img[obj.index] = {
    w = w,
    h = h,
    ox = obj.ox,
    oy = obj.oy,
    oz = obj.oz,
    rx = obj.rx,
    ry = obj.ry,
    rz = obj.rz,
    cx = obj.cx,
    cy = obj.cy,
    cz = obj.cz,
    zoom = obj.zoom,
    alpha = obj.alpha,
    aspect = obj.aspect,
  }
  P.caches[key] = c
end

function P.load(key)
  local c = P.caches[key]
  if c ~= nil and c.num ~= obj.num then
    -- キャッシュ有効時に「文字毎に個別オブジェクト」のチェックが切り替えられた
    -- 画像の枚数が変わるが今回はテキストが描画されていないので諦めるしかない
    P.del(key)
    P.beforekey = nil
    P.key = nil
    return
  end
  if c == nil then
    error("invalid internal state")
  end
  if obj.index == 0 then
    c.t = os.clock()
    c.d = 0
  end
  local cimg = c.img[obj.index]
  if cimg.w == 0 or cimg.h == 0 then
    -- 描画する必要がなさそう
    return
  end
  obj.setoption("drawtarget", "tempbuffer", cimg.w, cimg.h)
  obj.load("tempbuffer")
  local data, w, h = obj.getpixeldata()
  if not pcall(Extram.get, key .. "-" .. obj.index, data, w * 4 * h) then
    -- キャッシュからの読み込みに失敗した場合は諦める（手動で消された場合など）
    return
  end
  obj.putpixeldata(data)
  obj.ox = cimg.ox
  obj.oy = cimg.oy
  obj.oz = cimg.oz
  obj.rx = cimg.rx
  obj.ry = cimg.ry
  obj.rz = cimg.rz
  obj.cx = cimg.cx
  obj.cy = cimg.cy
  obj.cz = cimg.cz
  obj.zoom = cimg.zoom
  obj.alpha = cimg.alpha
  obj.aspect = cimg.aspect
end

P.lifetime = 3 -- 秒
P.gcinterval = 10 -- 秒
P.lastgc = 0
function P.gc()
  local t = os.clock()
  if P.lastgc + P.gcinterval >= t then
    -- まだあんまり時間が経ってない
    return
  end
  for key, c in pairs(P.caches) do
    if c.t + P.lifetime < t then
      -- 最近使われていないデータを発見
      if c.d == 0 then
        c.d = 1 -- 削除対象としてマーク
      else
        P.del(key) -- 実際に削除
      end
    end
  end
  P.lastgc = os.clock()
end

return P
