//
//  Library.swift
//  MusicPlayer
//
//  Created by Vladyslav Yakovlev on 22.01.2018.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import RealmSwift

class Library {
    
    static let main = Library()
    
    private let libraryQueue = DispatchQueue(label: "com.MusicPlayer.libraryQueue", qos: .userInteractive, attributes: .concurrent)
    
    private init() {}
    
    private var songs: Results<Song> {
        let ascending = songsSortMethod == .creationDate ? false : true
        return try! Realm().objects(Song.self).sorted(byKeyPath: songsSortMethod.rawValue, ascending: ascending)
    }
    
    var songsCount: Int {
        return try! Realm().objects(Song.self).count
    }
    
    private var albums: Results<Album> {
        let ascending = albumsSortMethod == .creationDate ? false : true
        return try! Realm().objects(Album.self).sorted(byKeyPath: albumsSortMethod.rawValue, ascending: ascending)
    }
    
    var albumsCount: Int {
        return try! Realm().objects(Album.self).count
    }
    
    private var playlists: Results<Playlist> {
        let ascending = playlistsSortMethod == .creationDate ? false : true
        return try! Realm().objects(Playlist.self).sorted(byKeyPath: playlistsSortMethod.rawValue, ascending: ascending)
    }
    
    var playlistsCount: Int {
        return try! Realm().objects(Playlist.self).count
    }
    
    var songsWithoutAlbum: [Song] {
        return Array(songs.filter("album = nil"))
    }
    
    func songsForAdding(for album: Album) -> [Song] {
        let predicate = NSPredicate(format: "album = nil || album = %@", album)
        return Array(songs.filter(predicate))
    }
    
    func addSong(_ song: Song) {
        DispatchQueue.global(qos: .userInteractive).async {
            let realm = try! Realm()
            try! realm.write {
                realm.add(song)
            }
            realm.refresh()
        }
    }
    
    func addSong(with location: URL, title: String, completion: @escaping () -> ()) {
        libraryQueue.async {
            let song = Song(title: title, url: location)
            let realm = try! Realm()
            try! realm.write {
                realm.add(song)
            }
            DispatchQueue.main.async {
                try! Realm().refresh()
                completion()
            }
        }
    }
    
    func addAlbum(with title: String, artist: String, songs: [Song], artwork: UIImage?) {
        let album = Album(title: title, artist: artist)
        album.artwork = artwork
        let realm = try! Realm()
        try! realm.write {
            for song in songs {
                song.album = album
            }
            realm.add(album)
        }
        realm.refresh()
    }
    
    func editAlbum(_ album: Album, with title: String, artist: String, songs: [Song], artwork: UIImage?) {
        let realm = try! Realm()
        try! realm.write {
            album.title = title
            album.artist = artist
            album.artwork = artwork
            for song in album.songs {
                song.album = nil
            }
            for song in songs {
                song.album = album
            }
        }
        realm.refresh()
    }
    
    func song(for index: Int, completion: @escaping (Song) -> ()) {
        libraryQueue.async {
            let song = self.songs[index]
            let songRef = ThreadSafeReference(to: song)
            DispatchQueue.main.async {
                let realm = try! Realm()
                guard let song = realm.resolve(songRef) else {
                    return
                }
                completion(song)
            }
        }
    }
    
    func album(for index: Int, completion: @escaping (Album) -> ()) {
        libraryQueue.async {
            let album = self.albums[index]
            let albumRef = ThreadSafeReference(to: album)
            DispatchQueue.main.async {
                let realm = try! Realm()
                guard let album = realm.resolve(albumRef) else {
                    return
                }
                completion(album)
            }
        }
    }
    
    func playlist(for index: Int, completion: @escaping (Playlist) -> ()) {
        libraryQueue.async {
            let playlist = self.playlists[index]
            let playlistRef = ThreadSafeReference(to: playlist)
            DispatchQueue.main.async {
                let realm = try! Realm()
                guard let playlist = realm.resolve(playlistRef) else {
                    return
                }
                completion(playlist)
            }
        }
    }
    
    func removeSong(with index: Int, completion: @escaping () -> ()) {
        libraryQueue.async {
            let song = self.songs[index]
            self.removeSong(song) {
                completion()
            }
        }
    }
    
    func removeAlbum(with index: Int, completion: @escaping () -> ()) {
        libraryQueue.async {
            let album = self.albums[index]
            self.removeAlbum(album) {
                completion()
            }
        }
    }
    
    func removeSong(with id: String, completion: @escaping () -> ()) {
        libraryQueue.async {
            guard let song = self.song(with: id) else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            self.removeSong(song) {
                completion()
            }
        }
    }
    
    func renameSong(with index: Int, with name: String, completion: @escaping () -> ()) {
        libraryQueue.async {
            let song = self.songs[index]
            self.renameSong(song, with: name) {
                completion()
            }
        }
    }
    
    func renameSong(with id: String, with name: String, completion: @escaping () -> ()) {
        libraryQueue.async {
            guard let song = self.song(with: id) else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            self.renameSong(song, with: name) {
                completion()
            }
        }
    }
    
    func renameSong(_ song: Song, with name: String, completion: @escaping () -> ()) {
        let realm = try! Realm()
        try! realm.write {
            song.title = name
        }
        DispatchQueue.main.async {
            try! Realm().refresh()
            completion()
        }
    }
    
    func removeSong(_ song: Song, completion: @escaping () -> ()) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(song)
        }
        DispatchQueue.main.async {
            try! Realm().refresh()
            completion()
        }
    }
    
    func removeSongFromAlbum(_ song: Song, completion: @escaping () -> ()) {
        let realm = try! Realm()
        try! realm.write {
            song.album = nil
        }
        DispatchQueue.main.async {
            try! Realm().refresh()
            completion()
        }
    }
    
    func removeAlbum(_ album: Album, completion: @escaping () -> ()) {
        let realm = try! Realm()
        try! realm.write {
            album.artwork = nil
            realm.delete(album)
        }
        DispatchQueue.main.async {
            try! Realm().refresh()
            completion()
        }
    }
    
    func addSong(_ song: Song, to album: Album) {
        let realm = try! Realm()
        try! realm.write {
            song.album = album
        }
        realm.refresh()
    }
    
    private func song(with id: String) -> Song? {
        return try! Realm().object(ofType: Song.self, forPrimaryKey: id)
    }

    
}

extension Library {
    
    enum SortMethod: String {
        
        case title
        case artist
        case creationDate
    }
    
    var songsSortMethod: SortMethod {
        get {
            return getSortMethod(for: .songs)
        }
        set {
            setSortMethod(newValue, for: .songs)
        }
    }
    
    var albumsSortMethod: SortMethod {
        get {
            return getSortMethod(for: .albums)
        }
        set {
            setSortMethod(newValue, for: .albums)
        }
    }
    
    var playlistsSortMethod: SortMethod {
        get {
            return getSortMethod(for: .playlists)
        }
        set {
            setSortMethod(newValue, for: .playlists)
        }
    }
    
    private func getSortMethod(for item: LibraryItems) -> SortMethod {
        let key: String
        switch item {
        case .songs : key = UserDefaultsKeys.songsSortMethod
        case .albums : key = UserDefaultsKeys.albumsSortMethod
        case .playlists : key = UserDefaultsKeys.playlistsSortMethod
        }
        if let sortMethod = UserDefaults.standard.string(forKey: key) {
            return SortMethod(rawValue: sortMethod)!
        }
        return .creationDate
    }
    
    private func setSortMethod(_ method: SortMethod, for item: LibraryItems) {
        let key: String
        switch item {
        case .songs : key = UserDefaultsKeys.songsSortMethod
        case .albums : key = UserDefaultsKeys.albumsSortMethod
        case .playlists : key = UserDefaultsKeys.playlistsSortMethod
        }
        UserDefaults.standard.set(method.rawValue, forKey: key)
    }
}
