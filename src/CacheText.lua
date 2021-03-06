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

-- @param message メッセージ本文
-- @param mode 動作モード
--             -1 = 常に最新データを使う
--              0 = オブジェクト編集中以外はキャッシュを使う
--              1 = 常にキャッシュを使う
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
  if c ~= nil and (mode == 0 and c.frame == obj.frame and obj.getoption("gui") or c.msg ~= P.msg)
  or mode == -1 then
    -- 編集中カーソル移動せずに再描画された（サイズを変更した場合など）か、
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
  local c = P.caches[key]
  if c == nil then
    c = {
      t = os.clock(),
      frame = obj.frame,
      d = 0,
      msg = P.msg,
      num = obj.num,
      img = {},
    }
    P.caches[key] = c
  end
  if obj.w == 0 or obj.h == 0 then
    return
  end
  -- 画像データがありそうならキャッシュに書き込む
  local data, w, h = obj.getpixeldata()
  Extram.put(key .. "-" .. obj.index, data, w * 4 * h)
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
end

function P.load(key)
  local c = P.caches[key]
  if c == nil then
    error("invalid internal state")
  end
  if c.num ~= obj.num then
    -- キャッシュ有効時に「文字毎に個別オブジェクト」のチェックが切り替えられた
    -- 画像の枚数が変わるが今回はテキストが描画されていないので諦めるしかない
    P.del(key)
    P.beforekey = nil
    P.key = nil
    return
  end
  if obj.index == 0 then
    c.t = os.clock()
    c.frame = obj.frame
    c.d = 0
  end
  local cimg = c.img[obj.index]
  if cimg == nil then
    -- 描画する必要がなさそう
    if obj.getoption("multi_object") then
      -- フォントサイズ 1 の Arial のピリオドが残ってしまうので消す
      obj.setoption("drawtarget", "tempbuffer", 1, 1)
      obj.load("tempbuffer")
    end
    return
  end
  obj.setoption("drawtarget", "tempbuffer", cimg.w, cimg.h)
  obj.load("tempbuffer")
  local data, w, h = obj.getpixeldata()
  if not pcall(Extram.get, key .. "-" .. obj.index, data, w * 4 * h) then
    -- キャッシュからの読み込みに失敗した場合は諦める（手動で消された場合など）
    -- データに不整合が起きているので一旦すべて仕切り直す
    P.del(key)
    P.beforekey = nil
    P.key = nil
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
