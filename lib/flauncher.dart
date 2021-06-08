/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:typed_data';

import 'package:flauncher/application_info.dart';
import 'package:flauncher/apps.dart';
import 'package:flauncher/wallpaper.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/settings_panel.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class FLauncher extends StatefulWidget {
  @override
  _FLauncherState createState() => _FLauncherState();
}

class _FLauncherState extends State<FLauncher> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Consumer<Wallpaper>(
            builder: (_, wallpaper, __) =>
                _wallpaper(context, wallpaper.wallpaperBytes),
          ),
          Scaffold(
            appBar: _appBar(context),
            body: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Consumer<Apps>(
                    builder: (context, apps, _) => ListView(
                      controller: _scrollController,
                      children: [
                        ..._favorites(context, apps.favorites),
                        Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
                          child: Text(
                            "Applications",
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: _gridDelegate(),
                          itemCount: apps.applications.length,
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemBuilder: (_, index) => Focus(
                            canRequestFocus: false,
                            onFocusChange: (focused) {
                              if (focused) {
                                _adjustScroll(index, apps.applications.length);
                              }
                            },
                            child: AppCard(
                              application: apps.applications[index],
                              autofocus: index == 0 && apps.favorites.isEmpty,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) =>
                      snapshot.connectionState == ConnectionState.done
                          ? Text(
                              "v${snapshot.data!.version}",
                              style: Theme.of(context).textTheme.overline,
                            )
                          : Container(),
                )
              ],
            ),
          ),
        ],
      );

  AppBar _appBar(BuildContext context) => AppBar(
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 20,
            icon: Icon(Icons.settings_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => SettingsPanel(),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 32),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 64,
                height: 24,
                child: TimeWidget(),
              ),
            ),
          ),
        ],
      );

  Widget _wallpaper(BuildContext context, Uint8List? wallpaperImage) =>
      wallpaperImage != null
          ? Image.memory(
              wallpaperImage,
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            )
          : Container(color: Theme.of(context).backgroundColor);

  SliverGridDelegate _gridDelegate() =>
      SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 16 / 9,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12);

  List<Widget> _favorites(
          BuildContext context, List<ApplicationInfo> favorites) =>
      favorites.isNotEmpty
          ? [
              Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  "Favorites",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: favorites.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.all(8),
                  itemBuilder: (_, index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: AppCard(
                        application: favorites[index],
                        autofocus: index == 0,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          : [
              Container(height: 80),
            ];

  void _adjustScroll(int index, int appsCount) {
    void scroll(double position) => _scrollController.animateTo(position,
        duration: Duration(milliseconds: 100), curve: Curves.easeInOut);

    final currentRow = (index / 6).floor();
    final totalRows = (appsCount / 6).floor();

    if (currentRow == 0) {
      scroll(0.0);
    } else if (currentRow == totalRows) {
      scroll(_scrollController.position.maxScrollExtent);
    }
  }
}
