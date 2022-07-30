///  Jh_cascade_tree_picker.dart
///
///  Created by iotjin on 2022/07/23.
///  description: 级级选择器（树形结构数据、支持搜索）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/jh_common/jh_form/jh_searchbar.dart';
import '/project/configs/colors.dart';
import '/project/provider/theme_provider.dart';
import '/project/routes/jh_nav_utils.dart';

const String _labelKey = 'label';
const String _childrenKey = 'children';
const String _titleText = '请选择';
const String _tabText = '请选择';
const String _searchHintText = '搜索';
const String _splitString = ' / ';
const double _headerHeight = 50.0;
const double _searchBarHeight = 58.0;
const double _headerRadius = 10.0;
const double _lineHeight = 0.5;
const double _itemHeight = 50.0;
const double _titleFontSize = 18.0;
const double _textFontSize = 16.0;
const double _searchResultTextFontSize = 14.0;

/// 选择回调，返回选中末级节点对象和所有节点数组
typedef _ClickCallBack = void Function(dynamic selectItem, dynamic selectArr);

class JhCascadeTreePicker {
  static void show(
    BuildContext context, {
    required List data, // tree数组
    String labelKey: _labelKey, // tree数据的文字字段
    String childrenKey: _childrenKey, // tree数据的children字段
    String title: _titleText,
    String tabText: _tabText,
    bool isShowSearch: true,
    String searchHintText: _searchHintText,
    String splitString: _splitString, // 搜索结果显示时分割两级的字符串
    bool isShowRadius: true,
    _ClickCallBack? clickCallBack,
  }) {
    if (data.length <= 0) {
      return;
    }
    var _radius = isShowRadius ? _headerRadius : 0.0;

    showModalBottomSheet<void>(
      context: context,
      // 使用true则高度不受16分之9的最高限制
      isScrollControlled: true,
      // 设置圆角
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_radius),
          topRight: Radius.circular(_radius),
        ),
      ),
      // 抗锯齿
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        return SafeArea(
          child: JhCascadePickerView(
            data: data,
            labelKey: labelKey,
            childrenKey: childrenKey,
            title: title,
            tabText: tabText,
            isShowSearch: isShowSearch,
            searchHintText: searchHintText,
            splitString: splitString,
            clickCallBack: clickCallBack,
          ),
        );
      },
    );
  }
}

class JhCascadePickerView extends StatefulWidget {
  const JhCascadePickerView({
    Key? key,
    required this.data,
    this.labelKey: _labelKey,
    this.childrenKey: _childrenKey,
    this.title: _titleText,
    this.tabText: _tabText,
    this.isShowSearch: true,
    this.searchHintText: _searchHintText,
    this.splitString: _splitString,
    this.clickCallBack,
  }) : super(key: key);

  final List? data; // tree数组
  final String labelKey; // tree数据的文字字段
  final String childrenKey; // tree数据的children字段
  final String title;
  final String tabText;
  final bool isShowSearch;
  final String searchHintText;
  final String splitString;
  final _ClickCallBack? clickCallBack;

  @override
  State<JhCascadePickerView> createState() => _JhCascadePickerViewState();
}

class _JhCascadePickerViewState extends State<JhCascadePickerView> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();

  // TabBar 数组
  List<Tab> _myTabs = <Tab>[];

  // 当前列表数据
  List _mList = [];

  // 多级联动选择的position
  List<int> _positions = [];

  // 索引
  int _index = 0;

  // 搜索数据
  List _searchData = [];
  bool _isShowSearchResult = false;
  String _searchKeyword = '';
  List _searchTreeTempData = [];

  @override
  void initState() {
    super.initState();

    _initData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initData() {
    if (widget.data != null) {
      List dataArr = widget.data!;
      for (int i = 0; i < dataArr.length; i++) {
        _myTabs.add(Tab(text: i == 0 ? widget.tabText : ''));
        _positions.add(0);
      }
      _mList = dataArr;
      _tabController = TabController(vsync: this, length: dataArr.length);
      _tabController?.animateTo(_index, duration: Duration.zero);
    }
  }

  /// 判断Children是否为空
  bool _isNotEmptyChildren(listData) {
    if (listData.containsKey(widget.childrenKey) &&
        listData[widget.childrenKey] != null &&
        listData[widget.childrenKey].length > 0) {
      return true;
    }
    return false;
  }

  void _setIndex(int index) {
    _index = index;
  }

  void _indexIncrement() {
    _index++;
  }

  /// tabBar点击后更新数据
  void _setList(int index) {
    if (widget.data != null) {
      List dataArr = widget.data!;
      if (dataArr.length > index) {
        if (index == 0) {
          _mList = dataArr;
        } else {
          // 获取点击tabBar的数据（根据上一级tabBar文字获取）
          var tabText = _myTabs[index - 1].text;
          if (tabText != widget.tabText) {
            var tempData = _getTreeDataByName(dataArr, tabText);
            _mList = tempData[widget.childrenKey];
          }
        }
      }
    }
  }

  /// 根据节点的文字获取对应节点的数据
  _getTreeDataByName(treeArr, name) {
    for (int i = 0; i < treeArr.length; i++) {
      var item = treeArr[i];
      if (treeArr[i][widget.labelKey] == name) {
        return item;
      } else {
        if (_isNotEmptyChildren(item)) {
          var res = _getTreeDataByName(item[widget.childrenKey], name);
          if (res != null) {
            return res;
          }
        }
      }
    }
  }

  /// 选项点击后设置下一级数据并改变tabBar
  void _setListAndChangeTab() {
    // 这里的index已经+1
    if (widget.data != null) {
      List dataArr = widget.data!;
      if (dataArr.length > _index - 1 && dataArr.length != _index) {
        _mList = _mList[_positions[_index - 1]][widget.childrenKey];
        _myTabs.asMap().forEach((i, e) {
          if (i > _index - 1) {
            if (i == _index) {
              _myTabs[i] = Tab(text: widget.tabText);
            } else {
              _myTabs[i] = Tab(text: '');
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 默认颜色
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var _bgColor = isDark ? KColors.kPickerBgDarkColor : KColors.kPickerBgColor;
    var _headerColor = isDark ? KColors.kPickerHeaderDarkColor : KColors.kPickerHeaderColor;
    var _titleColor = isDark ? KColors.kPickerTitleDarkColor : KColors.kPickerTitleColor;
    var _lineColor = isDark ? KColors.kPickerHeaderLineDarkColor : KColors.kPickerHeaderLineColor;
    var _textColor = isDark ? KColors.kPickerTextDarkColor : KColors.kPickerTextColor;

    return Container(
      color: _bgColor,
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 11.0 / 16.0,
          child: Container(
            child: Stack(
              children: [
                // header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: _headerHeight,
                    color: _headerColor,
                    alignment: Alignment.center,
                    child: Text(widget.title, style: TextStyle(fontSize: _titleFontSize, color: _titleColor)),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => JhNavUtils.goBack(context),
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      height: _headerHeight,
                      width: _headerHeight * 2,
                      child: Icon(
                        Icons.close,
                        color: _titleColor,
                      ),
                    ),
                  ),
                ),
                _searchBar(),
                Offstage(
                  offstage: !_isShowSearchResult,
                  child: _searchResultView(_bgColor, _textColor, _lineColor),
                ),
                Offstage(
                  offstage: _isShowSearchResult,
                  child: _mainWidget(_bgColor, _textColor, _lineColor),
                ),
              ],
            ),
          )),
    );
  }

  Widget _mainWidget(Color _bgColor, Color _textColor, Color _lineColor) {
    // 默认颜色
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var indicatorColor = KColors.kThemeColor;
    var labelColor = KColors.kThemeColor;
    var _unselectedLabelColor = isDark ? KColors.kBlackTextDarkColor : KColors.kBlackTextColor;

    // TODO: 通过ThemeProvider进行主题管理
    final provider = Provider.of<ThemeProvider>(context);
    var _indicatorColor = provider.isDark() ? indicatorColor : provider.getThemeColor();
    var _labelColor = provider.isDark() ? labelColor : provider.getThemeColor();

    return Container(
      margin: EdgeInsets.only(top: _headerHeight + (widget.isShowSearch ? _searchBarHeight : 0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: _lineHeight, child: Container(color: _lineColor)),
          Container(
            color: _bgColor,
            child: TabBar(
              tabs: _myTabs,
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: _labelColor,
              unselectedLabelColor: _unselectedLabelColor,
              indicatorColor: _indicatorColor,
              onTap: (index) {
                if ((_myTabs[index].text ?? '').isEmpty) {
                  // 拦截点击事件
                  _tabController?.animateTo(_index);
                  return;
                }
                setState(() {
                  _setList(index);
                  _setIndex(index);
                  _scrollController.animateTo(
                    _positions[_index] * _itemHeight,
                    duration: Duration(milliseconds: 10),
                    curve: Curves.ease,
                  );
                });
              },
            ),
          ),
          SizedBox(height: _lineHeight, child: Container(color: _lineColor)),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemExtent: _itemHeight,
              itemBuilder: (_, index) {
                return _buildItem(index, _bgColor, _textColor, _labelColor);
              },
              itemCount: _mList.length,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItem(int index, Color _bgColor, Color _textColor, Color _themeColor) {
    final bool flag = _mList[index][widget.labelKey] == _myTabs[_index].text;
    return InkWell(
      child: Container(
        color: _bgColor,
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Row(
          children: <Widget>[
            Text(
              _mList[index][widget.labelKey],
              style: TextStyle(fontSize: _textFontSize, color: flag ? _themeColor : _textColor),
            ),
            SizedBox(width: 8),
            Visibility(
              visible: flag,
              child: Icon(Icons.check, size: 15, color: _themeColor),
            )
          ],
        ),
      ),
      onTap: () {
        setState(() {
          _myTabs[_index] = Tab(text: _mList[index][widget.labelKey]);
          _positions[_index] = index;
          _indexIncrement();
          if (_isNotEmptyChildren(_mList[_positions[_index - 1]])) {
            _setListAndChangeTab();
          } else {
            // 获取选中的索引数组
            // var tempIndexArr = List.from(_positions);
            // if (_index <= tempIndexArr.length) {
            //   tempIndexArr = tempIndexArr.sublist(0, _index);
            // }
            // 根据末级节点查出包含父节点的数据
            List res = _findParentNodeDataByName(widget.data!, _mList[index][widget.labelKey]);
            // 选择回调
            widget.clickCallBack?.call(res.last, res);
            JhNavUtils.goBack(context);
            _setIndex(_index - 1);
          }
          _scrollController.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.ease);
          _tabController?.animateTo(_index);
        });
      },
    );
  }

  /// 搜索框相关

  /// 根据搜索文字过滤数据
  _getSearchData(keyword) {
    var data = _getTreeDataByKeyword(keyword, widget.data!);
    _searchTreeTempData = data;
    var newData = _convertTreeToListData(data, data, []);
    return newData;
  }

  /// 根据关键字过滤树结构数据
  _getTreeDataByKeyword(keyWord, List treeArr) {
    var newArr = [];
    treeArr.forEach((item) {
      if (item[widget.labelKey].contains(keyWord)) {
        newArr.add(item);
      } else {
        if (_isNotEmptyChildren(item)) {
          var res = _getTreeDataByKeyword(keyWord, item[widget.childrenKey]);
          if (res != null && res.length > 0) {
            var obj = {...item, widget.childrenKey: res};
            newArr.add(obj);
          }
        }
      }
    });
    return newArr;
  }

  /// 把树结构数据打平为一维数组，拼接父节点和子节点作为搜索结果
  /// resultArr为返回结果，默认为[]
  _convertTreeToListData(List treeArr, List treeArr2, List resultArr) {
    for (int i = 0; i < treeArr.length; i++) {
      var item = treeArr[i];
      if (_isNotEmptyChildren(item)) {
        _convertTreeToListData(item[widget.childrenKey], treeArr2, resultArr);
      } else {
        // 找到末级节点，根据末级节点找到所有父节点进行拼接
        var res = _findParentNodeDataByName(treeArr2, item[widget.labelKey], onlyName: true);
        if (res != null && res.length > 0) {
          resultArr.add(res.join(widget.splitString));
        }
      }
    }
    return resultArr;
  }

  /// 根据末级节点的名字查找所有父节点的数据
  /// onlyName = false ,返回name数组 , 否则返回name和value对象数组
  _findParentNodeDataByName(List treeArr, name, {List result = const [], onlyName = false}) {
    var newArr = List.from(result);
    for (int i = 0; i < treeArr.length; i++) {
      var item = treeArr[i];
      var tempDict = Map.from(item);
      if (onlyName) {
        newArr.add(tempDict[widget.labelKey]);
      } else {
        tempDict.remove(widget.childrenKey);
        newArr.add(tempDict);
      }
      if (item[widget.labelKey] == name) {
        return newArr;
      }
      if (_isNotEmptyChildren(item)) {
        var res = _findParentNodeDataByName(item[widget.childrenKey], name, result: newArr, onlyName: onlyName);
        // 如果不是空则表示找到了，直接return，结束递归
        if (res != null && res.length > 0) {
          return res;
        }
      }
      // 到这里，意味着本次并不是需要的节点，则在result中移除
      newArr.removeLast();
    }
    return [];
  }

  Widget _searchBar() {
    return !widget.isShowSearch
        ? Container()
        : Container(
            margin: EdgeInsets.only(top: _headerHeight),
            child: JhSearchBar(
              hintText: widget.searchHintText,
              text: _searchKeyword,
              inputCallBack: (value) {
                setState(() {
                  _searchKeyword = value;
                  if (value.length > 0) {
                    _searchData = _getSearchData(value);
                    _isShowSearchResult = _searchData.length > 0;
                  } else {
                    _isShowSearchResult = false;
                  }
                });
              },
            ),
          );
  }

  Widget _searchResultView(Color _bgColor, Color _textColor, Color _lineColor) {
    return Container(
      color: _bgColor,
      margin: EdgeInsets.only(top: _headerHeight + (widget.isShowSearch ? _searchBarHeight : 0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: _lineHeight, child: Container(color: _lineColor)),
          Expanded(
            child: ListView.builder(
              itemExtent: _itemHeight,
              itemBuilder: (_, index) {
                return _buildSearchResultItem(index, _bgColor, _textColor, _lineColor);
              },
              itemCount: _searchData.length,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(index, Color _bgColor, Color _textColor, Color _lineColor) {
    return InkWell(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: _bgColor,
          border: Border(bottom: BorderSide(color: _lineColor, width: _lineHeight)),
        ),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Text(_searchData[index], style: TextStyle(fontSize: _searchResultTextFontSize, color: _textColor)),
            ),
          ],
        ),
      ),
      onTap: () {
        setState(() {
          var selectText = _searchData[index];
          List tempArr = selectText.split(widget.splitString);
          var lastNodeName = tempArr.last;
          List res = _findParentNodeDataByName(_searchTreeTempData, lastNodeName);
          // 选择回调
          widget.clickCallBack?.call(res.last, res);
          JhNavUtils.goBack(context);
        });
      },
    );
  }
}
